defmodule Defre.Def do
  defmacro def(call, expr \\ nil) do
    if Application.get_env(:defre, :enable, Mix.env() == :test) do
      quote do
        Defre.defre(unquote(call), unquote(expr))
      end
    else
      quote do
        Kernel.def(unquote(call), unquote(expr))
      end
    end
  end
end
