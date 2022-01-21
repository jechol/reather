defmodule Defri.NestedCallTest do
  use ExUnit.Case, async: false
  use Defri
  alias Defri.Rither

  defmodule Target do
    use Defri

    import Enum, only: [at: 2]

    defr top(list) do
      list |> List.flatten() |> inject() |> middle() |> run()
    end

    defr middle(list) do
      list |> bottom() |> inject() |> run()
    end

    defrp bottom(list) do
      %{pos: pos} <- ask()
      at(list, pos) |> inject()
    end
  end

  test "inject" do
    assert 1 == Target.top([[0], 1]) |> Rither.run(%{pos: 1})

    assert 20 ==
             Target.top([[0], 1]) |> Rither.run(mock(%{&List.flatten/1 => [10, 20, 30], pos: 1}))

    assert :imported_func ==
             Target.top([[0], 1]) |> Rither.run(mock(%{&Enum.at/2 => :imported_func, pos: 1}))

    assert :private_func ==
             Target.top([[0], 1])
             |> Rither.run(mock(%{&Target.bottom/1 => :private_func}))
  end
end
