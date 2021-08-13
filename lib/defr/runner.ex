defmodule Defr.Runner do
  def call_remote(mfa, args, ask_ret) do
    select_remote_fun(mfa, ask_ret) |> :erlang.apply(args)
  end

  def call_local({m, f, a}, original, args, ask_ret) do
    fun = :erlang.make_fun(m, f, a)

    case Map.fetch(ask_ret, fun) do
      {:ok, mock} -> :erlang.apply(mock, args)
      :error -> original.()
    end
  end

  def select_remote_fun({m, f, a}, ask_ret) do
    fun = :erlang.make_fun(m, f, a)
    Map.get(ask_ret, fun, fun)
  end
end
