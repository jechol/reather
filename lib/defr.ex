defmodule Defr do
  defmacro __using__(opts) do
    %Macro.Env{function: function} = __CALLER__

    if function == nil do
      quote do
        use Witchcraft, override_kernel: false
        import Algae.Reader, only: [ask: 0, ask: 1]
        import Defr, only: :macros

        Module.register_attribute(__MODULE__, :defr_funs, accumulate: true)
        @before_compile unquote(Defr.Inject)
      end
    else
      quote do
      end
    end
  end

  defmacro run(reader) do
    quote do
      unquote(reader) |> Algae.Reader.run(var!(deps))
    end
    |> tap(fn ast -> ast |> Macro.to_string() |> IO.puts() end)
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
    |> tap(fn ast -> ast |> Macro.to_string() |> IO.puts() end)
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
    |> tap(fn ast -> ast |> Macro.to_string() |> IO.puts() end)
  end

  defp find_func_module(name_arity, mod_funs, caller_mod) do
    remote =
      mod_funs
      |> Enum.find(fn {mod, funs} ->
        name_arity in funs
      end)

    if remote != nil do
      {remote_mod, _} = remote
      remote_mod
    else
      caller_mod
    end
  end

  defmacro inject(other) do
    other |> IO.inspect()
    raise "error"
  end

  defmacro defr(head, do: body) do
    # do_defr(head, body, __CALLER__)
    fa = Defr.Inject.get_fa(head)
    do_block = Defr.Inject.convert_do_block(body)

    result =
      quote do
        @defr_funs unquote(fa)
        def unquote(head) do
          unquote(do_block)
        end
      end

    result |> Macro.to_string() |> IO.puts()
    result
  end

  defmacro defrp(head, do: body) do
    # do_defr(head, body, __CALLER__)
    fa = Defr.Inject.get_fa(head)

    quote do
      @defr_funs unquote(fa)
      defp unquote(head) do
        use Witchcraft.Monad

        monad %Algae.Reader{} do
          deps <- Algae.Reader.ask()
          unquote(body)
        end
      end
    end
  end

  defp do_defr(head, body, env) do
    alias Defr.Inject

    original =
      quote do
        def unquote(head), unquote(body)
      end

    Inject.inject_function(head, body, env)
    |> trace(original, env)
  end

  # defp build_do_block({:__block__, ctx, lines}) do
  #   {:__block__, _, new_lines} =
  #     quote do
  #       var!(deps) <- Algae.Reader.ask()
  #       let _ = var!(deps)
  #     end

  #   {:__block__, ctx, new_lines ++ lines}
  # end

  # defp build_do_block({_, ctx, _} = line) do
  #   {:__block__, _, new_lines} =
  #     quote do
  #       var!(deps) <- Algae.Reader.ask()
  #       let _ = var!(deps)
  #     end

  #   {:__block__, ctx, new_lines ++ [line]}
  # end

  defp trace(injected, original, %Macro.Env{file: file, line: line}) do
    if Application.get_env(:defr, :trace, false) do
      dash = "=============================="

      IO.puts("""
      #{dash} defr #{file}:#{line} #{dash}
      #{original |> Macro.to_string()}
      #{dash} into #{dash}"
      #{injected |> Macro.to_string()}
      """)
    end

    injected
  end

  defmacro mock({:%{}, context, mocks}) do
    alias Defr.Mock

    {:%{}, context, mocks |> Enum.map(&Mock.decorate_with_fn/1)}
  end
end
