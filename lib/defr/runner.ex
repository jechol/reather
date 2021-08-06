defmodule Defr.Runner do
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
end
