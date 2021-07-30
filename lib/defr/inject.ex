defmodule Defr.Inject do
  @moduledoc false

  alias Defr.AST

  @uninjectable [:erlang, Kernel, Kernel.Utils]
  @modifiers [:import, :require, :use]

  defmacro __before_compile__(_env) do
    quote do
      def __defr__ do
        @defr
      end
    end
  end

  def inject_function(head, body, %Macro.Env{module: _mod, file: file, line: line} = env)
      when is_list(body) do
    inject_results =
      body
      |> Enum.map(fn
        {key = :do, blk} ->
          case blk |> inject_ast_recursively(env) do
            {:ok, {_, _, _} = value} ->
              {key, value}

            {:error, :modifier} ->
              raise CompileError,
                file: file,
                line: line,
                description: "Cannot import/require/use inside defre. Move it to module level."
          end

        {key, blk} ->
          {key, {blk, [], []}}
      end)

    injected_body =
      inject_results
      |> Enum.reduce([], fn
        {:do, {injected_blk, _, _}}, acc ->
          do_blk =
            {:do,
             quote do
               require Witchcraft.Monad

               Witchcraft.Monad.monad %Algae.Reader{} do
                 deps <- Algae.Reader.ask()

                 return(unquote(injected_blk))
               end
             end}

          acc ++ [do_blk]

        {key, {blk, _, _}}, acc ->
          acc ++ [{key, blk}]
      end)

    quote do
      unquote(accumulate_defr(head))
      def unquote(head), unquote(injected_body)
    end
  end

  defp accumulate_defr(head) do
    fa = get_fa(head)

    quote do
      Module.register_attribute(__MODULE__, :defr, accumulate: true)

      unless unquote(fa) in Module.get_attribute(__MODULE__, :defr) do
        @defr unquote(fa)
      end
    end
  end

  defp get_fa({:when, _, [name_args, _when_cond]}) do
    get_fa(name_args)
  end

  defp get_fa({name, _, args}) when is_list(args) do
    {name, args |> Enum.count()}
  end

  defp get_fa({name, _, _}) do
    {name, 0}
  end

  def inject_ast_recursively(blk, env) do
    with {:ok, ^blk} <- blk |> check_no_modifier_recursively() do
      {injected_blk, {captures, mods}} =
        blk
        |> expand_recursively!(env)
        |> mark_remote_call_recursively!()
        |> inject_recursively!()

      {:ok, {injected_blk, captures, mods}}
    end
  end

  defp check_no_modifier_recursively(ast) do
    case ast
         |> Macro.prewalk(:ok, fn
           _ast, {:error, :modifier} ->
             {nil, {:error, :modifier}}

           {modifier, _, _}, :ok when modifier in @modifiers ->
             {nil, {:error, :modifier}}

           ast, :ok ->
             {ast, :ok}
         end) do
      {expanded_ast, :ok} -> {:ok, expanded_ast}
      {_, {:error, :modifier}} -> {:error, :modifier}
    end
  end

  defp expand_recursively!(ast, env) do
    ast
    |> Macro.prewalk(fn
      {:@, _, _} = ast ->
        ast

      {:in, _, _} = ast ->
        ast

      ast ->
        Macro.expand(ast, env)
    end)
  end

  defp mark_remote_call_recursively!(ast) do
    ast
    |> Macro.prewalk(fn
      # capture
      {:&, c1, [{:/, c2, [mf, arity]}]} ->
        {:&, c1, [{:/, c2, [mf |> skip_inject(), arity]}]}

      # anonymous
      {:&, c1, [anonymous_fn]} ->
        {:&, c1, [anonymous_fn |> skip_inject()]}

      # rescue pattern matching
      {:->, c1, [left, right]} ->
        {:->, c1, [left |> Enum.map(&skip_inject/1), right]}

      ast ->
        ast
    end)
  end

  defp skip_inject({f, context, args}) when is_list(context) and is_list(args) do
    {f, [{:skip_inject, true} | context], args |> Enum.map(&skip_inject/1)}
  end

  defp skip_inject(ast) do
    ast
  end

  defp inject_recursively!(ast) do
    ast
    |> Macro.postwalk({[], []}, fn ast, {captures, mods} ->
      {injected_ast, new_caputres, new_mods} = inject(ast)
      {injected_ast, {new_caputres ++ captures, new_mods ++ mods}}
    end)
  end

  defp inject({_func, [{:skip_inject, true} | _], _args} = ast) do
    {ast, [], []}
  end

  defp inject({{:., _dot_ctx, [mod, name]}, _call_ctx, args} = ast)
       when is_atom(name) and is_list(args) do
    if AST.is_module_ast(mod) and AST.unquote_module_ast(mod) not in @uninjectable do
      arity = Enum.count(args)
      capture = AST.quote_function_capture({mod, name, arity})

      injected_call =
        quote do
          ret =
            Map.get(
              deps,
              unquote(capture),
              unquote(capture)
              # :erlang.make_fun(
              #   Map.get(deps, unquote(mod), unquote(mod)),
              #   unquote(name),
              #   unquote(arity)
              # )
            ).(unquote_splicing(args))

          if {unquote(name), unquote(arity)} in unquote(mod).__defr__() do
            ret |> Algae.Reader.run(deps)
          else
            ret
          end
        end

      # reader_call =
      #   if AST.unquote_module_ast(mod) in reader_modules do
      #     quote do
      #       unquote(injected_call) |> Algae.Reader.run(deps)
      #     end
      #   else
      #     injected_call
      #   end

      {injected_call, [capture], [mod]}
    else
      {ast, [], []}
    end
  end

  defp inject(ast) do
    {ast, [], []}
  end
end
