defmodule Defr.Runner do
  alias Algae.Reader

  def call_remote({m, f, a}, args, deps) do
    fun = :erlang.make_fun(m, f, a)
    Map.get(deps, fun, fun) |> :erlang.apply(args)
  end

  def call_local({m, f, a}, original, args, deps) do
    fun = :erlang.make_fun(m, f, a)

    case Map.fetch(deps, fun) do
      {:ok, mock} -> :erlang.apply(mock, args)
      :error -> original.()
    end
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
