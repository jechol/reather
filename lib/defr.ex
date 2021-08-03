defmodule Defr do
  defmacro __using__(_) do
    quote do
      import Defr, only: :macros
      use Witchcraft.Monad

      Module.register_attribute(__MODULE__, :defr_funs, accumulate: true)
      @before_compile unquote(Defr.Inject)
    end
  end

  defmacro defr(head, body) do
    do_defr(head, body, __CALLER__)
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
