defmodule Defr.Runner do
  def run({m, f, a}, args, deps) do
    ret = Kernel.apply(m, f, args)

    if Kernel.function_exported?(m, :__defr__, 0) and
         {f, a} in Kernel.apply(m, :__defr__, []) do
      ret |> Algae.Reader.run(deps)
    else
      ret
    end
  end
end
