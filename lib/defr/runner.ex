defmodule Defr.Runner do
  def run({m, f, a}, args, deps) do
    fun = :erlang.make_fun(m, f, a)
    ret = Map.get(deps, fun, fun) |> :erlang.apply(args)

    if Kernel.function_exported?(m, :__defr_funs__, 0) and
         {f, a} in Kernel.apply(m, :__defr_funs__, []) do
      ret |> Algae.Reader.run(deps)
    else
      ret
    end
  end
end
