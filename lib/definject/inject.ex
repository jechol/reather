defmodule Defre.Inject do
  @moduledoc false

  alias Defre.AST

  @uninjectable [:erlang, Kernel, Kernel.Utils]
  @modifiers [:import, :require, :use]

  def inject_function(
        head,
        body,
        %Macro.Env{module: _mod, file: file, line: line} = env,
        %{mode: {:reader, :either}, reader_modules: _reader_modules} = config
      )
      when is_list(body) do
    inject_results =
      body
      |> Enum.map(fn {key, blk} ->
        case blk |> inject_ast_recursively(env, config) do
          {:ok, {_, _, _} = value} ->
            {key, value}

          {:error, :modifier} ->
            raise CompileError,
              file: file,
              line: line,
              description: "Cannot import/require/use inside defre. Move it to module level."
        end
      end)

    injected_body =
      inject_results
      |> Enum.reduce([], fn
        {:do, {injected_blk, _, _}}, acc ->
          do_blk =
            {:do,
             quote do
               require Witchcraft.Monad

               Witchcraft.Monad.monad %Reader{} do
                 deps <- Algae.Reader.ask()

                 #  Defre.Check.validate_deps(
                 #    deps,
                 #    {unquote(captures), unquote(mods)},
                 #    unquote(Macro.escape({mod, name, arity}))
                 #  )

                 return(
                   Witchcraft.Monad.monad %Right{} do
                     unquote(injected_blk)
                   end
                 )
               end
             end}

          acc ++ [do_blk]

        {key, {injected_blk, _, _}}, acc ->
          acc ++ [{key, injected_blk}]
      end)

    quote do
      # unquote(injected_head)

      def unquote(head), unquote(injected_body)
    end
  end

  def inject_ast_recursively(blk, env, config) do
    with {:ok, ^blk} <- blk |> check_no_modifier_recursively() do
      {injected_blk, {captures, mods}} =
        blk
        |> expand_recursively!(env)
        |> mark_remote_call_recursively!()
        |> inject_recursively!(config)

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

  defp inject_recursively!(ast, config) do
    ast
    |> Macro.postwalk({[], []}, fn ast, {captures, mods} ->
      {injected_ast, new_caputres, new_mods} = inject(ast, config)
      {injected_ast, {new_caputres ++ captures, new_mods ++ mods}}
    end)
  end

  defp inject({_func, [{:skip_inject, true} | _], _args} = ast, _config) do
    {ast, [], []}
  end

  defp inject({{:., _dot_ctx, [mod, name]}, _call_ctx, args} = ast, %{
         mode: {:reader, :either},
         reader_modules: reader_modules
       })
       when is_atom(name) and is_list(args) do
    if AST.is_module_ast(mod) and AST.unquote_module_ast(mod) not in @uninjectable do
      arity = Enum.count(args)
      capture = AST.quote_function_capture({mod, name, arity})

      injected_call =
        quote do
          Map.get(
            deps,
            unquote(capture),
            :erlang.make_fun(
              Map.get(deps, unquote(mod), unquote(mod)),
              unquote(name),
              unquote(arity)
            )
          ).(unquote_splicing(args))
        end

      reader_call =
        if AST.unquote_module_ast(mod) in reader_modules do
          quote do
            unquote(injected_call) |> Algae.Reader.run(deps)
          end
        else
          injected_call
        end

      {reader_call, [capture], [mod]}
    else
      {ast, [], []}
    end
  end

  defp inject(ast, _config) do
    {ast, [], []}
  end
end
