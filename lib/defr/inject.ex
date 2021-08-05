defmodule Defr.Inject do
  @moduledoc false

  alias Defr.AST

  @uninjectable [:erlang, Kernel, Kernel.Utils]
  @modifiers [:import, :require, :use]

  defmacro __before_compile__(_env) do
    quote do
      def __defr_funs__ do
        @defr_funs
      end
    end
  end

  def inject_function(head, body, %Macro.Env{file: file, line: line} = env)
      when is_list(body) do
    inject_results =
      body
      |> Enum.map(fn
        {:do, blk} ->
          case blk |> inject_ast_recursively(env) do
            {:ok, injected_blk} ->
              {:do, injected_blk}

            {:error, :modifier} ->
              raise CompileError,
                file: file,
                line: line,
                description: "Cannot import/require/use inside defr. Move it to module level."
          end

        {key, blk} ->
          {key, blk}
      end)

    injected_body =
      inject_results
      |> Enum.reduce([], fn
        {:do, injected_blk}, acc ->
          acc ++ [{:do, convert_do_block(injected_blk)}]

        {key, blk}, acc ->
          acc ++ [{key, blk}]
      end)

    fa = get_fa(head)

    quote do
      @defr_funs unquote(fa)
      def unquote(head), unquote(injected_body)
    end
  end

  defp convert_do_block({:__block__, ctx, exprs}) do
    [last | except_last] = exprs |> Enum.reverse()

    monad_body =
      [
        quote do
          deps <- Algae.Reader.ask()
        end
        | except_last |> Enum.reverse()
      ] ++
        [
          quote do
            return(unquote(last))
          end
        ]

    quote do
      use Witchcraft.Monad

      monad %Algae.Reader{} do
        unquote({:__block__, ctx, monad_body})
        # deps <- Algae.Reader.ask()
        # unquote({:__block__, ctx, except_last |> Enum.reverse()})
        # return(unquote(last))
      end
    end
  end

  defp convert_do_block(expr) do
    quote do
      use Witchcraft.Monad

      monad %Algae.Reader{} do
        deps <- Algae.Reader.ask()
        return(unquote(expr))
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
      injected_blk =
        blk
        |> expand_recursively!(env)
        |> mark_remote_call_recursively!()
        |> Macro.postwalk(&inject/1)

      {:ok, injected_blk}
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

  defp inject({{:., _, [{:@, _, [{:@, _, [mod]}]}, name]}, _, args}) do
  end

  defp inject(
         {{:., [],
           [
             {:__aliases__, [],
              [
                {:@, [context: Elixir, import: Kernel],
                 [
                   {:@, [context: Elixir, import: Kernel],
                    [{:__aliases__, [context: Elixir, alias: false], [:A]}]}
                 ]},
                :B
              ]},
             :b
           ]}, [], '\n'}
       ) do
    {{:., [],
      [
        {:__aliases__, [],
         [
           {:@, [context: Elixir, import: Kernel],
            [
              {:@, [context: Elixir, import: Kernel],
               [{:__aliases__, [context: Elixir, alias: false], [:A]}]}
            ]},
           :B,
           :C
         ]},
        :b
      ]}, [], '\n'}
  end

  defp inject({:&, [], [{:/, _, _}]} = capture) do
    capture
  end

  defp inject({:inject, _, [{{:., _, [mod, name]}, _, args}]})
       when is_atom(name) and is_list(args) do
    arity = Enum.count(args)

    quote do
      Defr.Runner.call_remote({unquote(mod), unquote(name), unquote(arity)}, unquote(args), deps)
    end
  end

  defp inject({:inject, _, [{name, _, args} = local_call]})
       when is_atom(name) and is_list(args) do
    arity = Enum.count(args)

    quote do
      Defr.Runner.call_local(
        {__MODULE__, unquote(name), unquote(arity)},
        fn -> unquote(local_call) end,
        unquote(args),
        deps
      )
    end
  end

  defp inject({:run, _, [reader]}) do
    quote do
      unquote(reader) |> Algae.Reader.run(deps)
    end
  end

  # defp inject({:&, _, [{{:., _dot_ctx, [mod, name]}, _call_ctx, args} = _remote_call]})
  #      when is_atom(name) and is_list(args) do
  #   arity = Enum.count(args)

  #   quote do
  #     Defr.Runner.call_remote({unquote(mod), unquote(name), unquote(arity)}, unquote(args), deps)
  #     |> Defr.Runner.run_reader(deps)
  #   end
  # end

  # defp inject({:&, _, [{name, _call_ctx, args} = local_call]})
  #      when is_atom(name) and is_list(args) do
  #   arity = Enum.count(args)

  #   quote do
  #     Defr.Runner.call_remote(
  #       {__MODULE__, unquote(name), unquote(arity)},
  #       fn -> unquote(local_call) end,
  #       unquote(args),
  #       deps
  #     )
  #     |> Defr.Runner.run_reader(deps)
  #   end
  # end

  # defp inject({:&, _, [{_, _, _}]} = ast) do
  #   ast |> IO.inspect(label: "Uninspected AST")
  #   raise ""
  # end

  # defp inject({_func, [{:skip_inject, true} | _], _args} = ast) do
  #   ast
  # end

  # defp inject({{:., _, [_, :ask]}, _, _} = ast) do
  #   ast
  # end

  # defp inject({{:., _dot_ctx, [mod, name]}, _call_ctx, args} = ast)
  #      when is_atom(name) and is_list(args) do
  #   if AST.is_module_ast(mod) and AST.unquote_module_ast(mod) not in @uninjectable do
  #     arity = Enum.count(args)

  #     quote do
  #       Defr.Runner.call_remote({unquote(mod), unquote(name), unquote(arity)}, unquote(args), deps)
  #       |> Defr.Runner.run_reader(deps)
  #     end
  #   else
  #     ast
  #   end
  # end

  # defp inject({local_fun, ctx, args} = ast)
  #      when is_atom(local_fun) and is_list(ctx) and is_list(args) do
  #   quote do
  #     Defr.Runner.run_reader(unquote(ast))
  #   end
  # end

  defp inject(ast) do
    ast
  end
end
