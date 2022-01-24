defmodule Reather.NestedCallTest do
  use ExUnit.Case, async: false
  use Reather

  defmodule Target do
    use Reather

    import Enum, only: [at: 2]

    reather top(list) do
      list |> List.flatten() |> Reather.inject() |> middle()
    end

    reather middle(list) do
      list |> bottom() |> Reather.inject()
    end

    reatherp bottom(list) do
      %{pos: pos} <- Reather.ask()
      return at(list, pos) |> Reather.inject() |> Right.new()
    end
  end

  test "inject" do
    assert %Right{right: 1} == Target.top([[0], 1]) |> Reather.run(%{pos: 1})

    assert %Right{right: 20} ==
             Target.top([[0], 1])
             |> Reather.run(Reather.mock(%{&List.flatten/1 => [10, 20, 30], pos: 1}))

    assert %Right{right: :imported_func} ==
             Target.top([[0], 1])
             |> Reather.run(Reather.mock(%{&Enum.at/2 => :imported_func, pos: 1}))

    assert %Right{right: :private_func} ==
             Target.top([[0], 1])
             |> Reather.run(Reather.mock(%{&Target.bottom/1 => Right.new(:private_func)}))
  end
end
