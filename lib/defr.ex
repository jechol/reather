defmodule Defr do
  defmacro __using__([]) do
    quote do
      use Witchcraft, override_kernel: false
      import Algae.Reader, only: [ask: 0, ask: 1]
      import Defr, only: :macros

      Module.register_attribute(__MODULE__, :defr_funs, accumulate: true)
      @before_compile unquote(Defr)
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
    fa = Defr.Inject.get_fa(head)
    do_block = body |> Defr.Inject.convert_do_block()

    quote do
      @defr_funs unquote(fa)
      def unquote(head) do
        unquote(do_block)
      end
    end
  end

  defmacro defrp(head, do: body) do
    fa = Defr.Inject.get_fa(head)
    do_block = body |> Defr.Inject.convert_do_block()

    quote do
      @defr_funs unquote(fa)
      defp unquote(head) do
        unquote(do_block)
      end
    end
  end

  defmacro run(reader) do
    quote do
      unquote(reader) |> Algae.Reader.run(var!(deps))
    end
  end

  defmacro inject({{:., _, [mod, name]}, _, args})
           when is_atom(name) and is_list(args) do
    arity = Enum.count(args)

    quote do
      Defr.Runner.call_remote(
        {unquote(mod), unquote(name), unquote(arity)},
        unquote(args),
        var!(deps)
      )
    end
  end

  defmacro inject({name, _, args} = local_call)
           when is_atom(name) and is_list(args) do
    arity = Enum.count(args)
    %Macro.Env{module: caller_mod, functions: mod_funs} = __CALLER__
    mod = find_func_module({name, arity}, mod_funs, caller_mod)

    if mod == caller_mod do
      # Local call
      quote do
        Defr.Runner.call_local(
          {__MODULE__, unquote(name), unquote(arity)},
          fn -> unquote(local_call) end,
          unquote(args),
          var!(deps)
        )
      end
    else
      # Remote call
      mod_ast = quote do: unquote(mod)

      quote do
        unquote(mod_ast).unquote(name)(unquote_splicing(args)) |> Defr.inject()
      end
    end
  end

  defmacro mock({:%{}, context, mocks}) do
    alias Defr.Mock

    {:%{}, context, mocks |> Enum.map(&Mock.decorate_with_fn/1)}
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
end
