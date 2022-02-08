defmodule Reather.Macros do
  alias Algae.Either.{Left, Right}

  defmacro __using__([]) do
    quote do
      use Witchcraft, override_kernel: false
      alias Algae.Either.{Left, Right}

      import Reather.Macros, only: [reather: 1, reather: 2, reatherp: 2]

      unless Module.has_attribute?(__MODULE__, :reather_functions) do
        Module.register_attribute(__MODULE__, :reather_functions, accumulate: true)
        @before_compile Reather.Macros
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __reather_functions__ do
        @reather_functions
      end
    end
  end

  defmacro reather(head, do: body) do
    fa = get_fa(head)
    do_block = body |> convert_do_block()

    quote do
      @reather_functions unquote(fa)
      def unquote(head) do
        unquote(do_block)
      end
    end
    |> trace()
  end

  defmacro reatherp(head, do: body) do
    fa = get_fa(head)
    do_block = body |> convert_do_block()

    quote do
      @reather_functions unquote(fa)
      defp unquote(head) do
        unquote(do_block)
      end
    end
    |> trace()
  end

  defmacro reatherfy({:fn, env, clauses}) do
    injected =
      clauses
      |> Enum.map(fn {:->, env, [args, body]} ->
        {:->, env, [args, body |> convert_do_block()]}
      end)

    {:fn, env, injected}
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
    alias Reather.Mock

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

  defp convert_do_block({:__block__, ctx, exprs} = expr) do
    build_do_block(has_inject?(expr), ctx, exprs)
  end

  defp convert_do_block(expr) do
    build_do_block(has_inject?(expr), [], [expr])
  end

  defp has_inject?(exprs) do
    # False positive is okay.
    {^exprs, found?} =
      Macro.prewalk(exprs, false, fn
        {:inject, _, []} = ast, _ ->
          {ast, true}

        {{:., _, [_, :inject]}, _, []} = ast, _ ->
          {ast, true}

        _ = ast, found? ->
          {ast, found?}
      end)

    found?
  end

  defp build_do_block(has_inject?, ctx, exprs) do
    monad_body =
      if has_inject? do
        [
          quote do
            var!(ask_ret) <- Reather.ask()
          end
          | exprs
        ]
      else
        exprs
      end

    quote do
      use Witchcraft, override_kernel: false

      %Reather{} =
        reather do
          unquote({:__block__, ctx, monad_body})
        end
    end
  end

  @trace Application.compile_env(:reather, :trace, false)
  defp trace(ast) do
    if @trace do
      ast |> Macro.to_string() |> IO.puts()
      ast
    else
      ast
    end
  end

  defmacro reather(do: input) do
    sample = quote do: %Reather{}
    returnized = Witchcraft.Monad.desugar_return(input, sample)
    do_notation(returnized)
  end

  def do_notation(input) do
    [head | tail] = input |> normalize() |> Enum.reverse()

    wrapped_head =
      quote do
        unquote(head) |> Reather.Macros.wrap_in_reather()
      end

    Witchcraft.Foldable.left_fold(tail, wrapped_head, fn
      continue, {:let, _, [{:=, _, [assign, value]}]} ->
        quote do: unquote(value) |> (fn unquote(assign) -> unquote(continue) end).()

      continue, {:<-, _, [assign, value]} ->
        quote do
          import Witchcraft.Chain, only: [>>>: 2]

          # Here we accept not only Reather, but also Either for smooth migration.
          unquote(value) |> Reather.Macros.wrap_in_reather() >>>
            fn unquote(assign) -> unquote(continue) end
        end

      continue, value ->
        quote do
          import Witchcraft.Chain, only: [>>>: 2]

          # Here we accept not only Reather, but also Either for smooth migration.
          unquote(value) |> Reather.Macros.wrap_in_reather() >>>
            fn _ -> unquote(continue) end
        end
    end)
  end

  @doc false
  def normalize({:__block__, _, inner}), do: inner
  def normalize(single) when is_list(single), do: [single]
  def normalize(plain), do: List.wrap(plain)

  def wrap_in_reather(%Reather{} = r), do: r
  def wrap_in_reather(non_reather), do: Witchcraft.Applicative.of(%Reather{}, non_reather)
end
