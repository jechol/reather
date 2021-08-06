defmodule Defr.Runner do
  def call_remote({m, f, a}, args, ask_ret) do
    fun = :erlang.make_fun(m, f, a)
    Map.get(ask_ret, fun, fun) |> :erlang.apply(args)
  end

  def call_local({m, f, a}, original, args, ask_ret) do
    fun = :erlang.make_fun(m, f, a)

    case Map.fetch(ask_ret, fun) do
      {:ok, mock} -> :erlang.apply(mock, args)
      :error -> original.()
    end
  end
end
