defmodule Defr do
  defmacro __using__([]) do
    quote do
      use Witchcraft, override_kernel: false
      import Algae.Reader, only: [ask: 0, ask: 1]
      import Defr, only: :macros

      unless Module.has_attribute?(__MODULE__, :defr_funs) do
        Module.register_attribute(__MODULE__, :defr_funs, accumulate: true)
        @before_compile Defr
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __defr_funs__ do
        @defr_funs
      end
    end
  end

  defmacro defr(head, do: body) do
    fa = get_fa(head)
    do_block = body |> convert_do_block()

    quote do
      @defr_funs unquote(fa)
      def unquote(head) do
        unquote(do_block)
      end
    end
    |> trace()
  end

  defmacro defrp(head, do: body) do
    fa = get_fa(head)
    do_block = body |> convert_do_block()

    quote do
      @defr_funs unquote(fa)
      defp unquote(head) do
        unquote(do_block)
      end
    end
    |> trace()
  end

  defmacro readerfy({:fn, env, clauses}) do
    injected =
      clauses
      |> Enum.map(fn {:->, env, [args, body]} ->
        {:->, env, [args, body |> convert_do_block()]}
      end)

    {:fn, env, injected}
  end

  defmacro run(reader, nested_env \\ Macro.escape(%{})) do
    quote do
      env = Map.merge(unquote(nested_env), var!(ask_ret))
      unquote(reader) |> Algae.Reader.run(env)
    end
    |> trace()
  end

  # Capture
  defmacro inject(
             {:&, _, [{:/, _, [{{:., _, [mod, name]}, [{:no_parens, true}, _], []}, arity]}]}
           ) do
    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Map.get(var!(ask_ret), fun, fun)
    end
    |> trace()
  end

  defmacro inject({:&, _, [{:/, _, [{name, _, _}, arity]}]} = ast) do
    %Macro.Env{module: caller_mod, functions: mod_funs} = __CALLER__
    mod = find_func_module({name, arity}, mod_funs, caller_mod)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Map.get(var!(ask_ret), fun, unquote(ast))
    end
    |> trace()
  end

  # Call
  defmacro inject({{:., _, [mod, name]}, _, args})
           when is_atom(name) and is_list(args) do
    arity = Enum.count(args)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Map.get(var!(ask_ret), fun, fun) |> :erlang.apply(unquote(args))
    end
    |> trace()
  end

  defmacro inject({name, _, args} = local_call)
           when is_atom(name) and is_list(args) do
    arity = Enum.count(args)
    %Macro.Env{module: caller_mod, functions: mod_funs} = __CALLER__
    mod = find_func_module({name, arity}, mod_funs, caller_mod)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))

      case Map.fetch(var!(ask_ret), fun) do
        {:ok, mock} -> :erlang.apply(mock, unquote(args))
        :error -> unquote(local_call)
      end
    end
    |> trace()
  end

  defmacro mock({:%{}, context, mocks}) do
    alias Defr.Mock

    {:%{}, context, mocks |> Enum.map(&Mock.decorate_with_fn/1)}
    |> trace()
  end

  # Private

  defp find_func_module(name_arity, mod_funs, caller_mod) do
    remote =
      mod_funs
      |> Enum.find(fn {_mod, funs} ->
        name_arity in funs
      end)

    if remote != nil do
      {remote_mod, _} = remote
      remote_mod
    else
      caller_mod
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

  defp convert_do_block({:__block__, ctx, exprs}) do
    build_do_block(ctx, exprs |> Enum.take(Enum.count(exprs) - 1), exprs |> List.last())
  end

  defp convert_do_block({_, ctx, _} = expr) do
    build_do_block(ctx, [], expr)
  end

  # Private

  defp build_do_block(ctx, except_last, last) do
    monad_body =
      [
        quote do
          var!(ask_ret) <- Algae.Reader.ask()
        end,
        quote do
          let(_ = var!(ask_ret))
        end
        | except_last
      ] ++
        [
          quote do
            return(
              (
                use Witchcraft
                unquote(last)
              )
            )
          end
        ]

    quote do
      use Witchcraft

      monad %Algae.Reader{} do
        unquote({:__block__, ctx, monad_body})
      end
    end
  end

  @trace Application.compile_env(:defr, :trace, false)
  defp trace(ast) do
    if @trace do
      ast |> Macro.to_string() |> IO.puts()
      ast
    else
      ast
    end
  end
end
