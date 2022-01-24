defmodule Reather.NestedCallTest do
  use ExUnit.Case, async: false
  use Reather
  alias Reather.Rither

  defmodule Target do
    use Reather

    import Enum, only: [at: 2]

    reather top(list) do
      list |> List.flatten() |> inject() |> middle() |> run()
    end

    reather middle(list) do
      list |> bottom() |> inject() |> run()
    end

    reatherp bottom(list) do
      %{pos: pos} <- ask()
      at(list, pos) |> inject() |> Right.new()
    end
  end

  test "inject" do
    assert %Right{right: 1} == Target.top([[0], 1]) |> Rither.run(%{pos: 1})

    assert %Right{right: 20} ==
             Target.top([[0], 1]) |> Rither.run(mock(%{&List.flatten/1 => [10, 20, 30], pos: 1}))

    assert %Right{right: :imported_func} ==
             Target.top([[0], 1]) |> Rither.run(mock(%{&Enum.at/2 => :imported_func, pos: 1}))

    assert %Right{right: :private_func} ==
             Target.top([[0], 1])
             |> Rither.run(mock(%{&Target.bottom/1 => Right.new(:private_func)}))
  end
end
