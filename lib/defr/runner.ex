defmodule Defr.Runner do
  alias Algae.Reader

  def call_mock({m, f, a}, args, deps) do
    fun = :erlang.make_fun(m, f, a)
    Map.get(deps, fun, fun) |> :erlang.apply(args)
  end

  def run_reader(%Reader{} = r, deps) do
    r |> Reader.run(deps)
  end

  def run_reader(non_reader, _deps) do
    non_reader
  end

  def is_defr_fun?({m, f, a}) do
    Kernel.function_exported?(m, :__defr_funs__, 0) and
      {f, a} in Kernel.apply(m, :__defr_funs__, [])
  end
end
