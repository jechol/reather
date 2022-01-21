defmodule Defr.NestedCallTest do
  use ExUnit.Case, async: false
  use Defr
  alias Algae.Reader

  defmodule Target do
    use Defr

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
    assert 1 == Target.top([[0], 1]) |> Reader.run(%{pos: 1})

    assert 20 ==
             Target.top([[0], 1]) |> Reader.run(mock(%{&List.flatten/1 => [10, 20, 30], pos: 1}))

    assert :imported_func ==
             Target.top([[0], 1]) |> Reader.run(mock(%{&Enum.at/2 => :imported_func, pos: 1}))

    assert :private_func ==
             Target.top([[0], 1])
             |> Reader.run(mock(%{&Target.bottom/1 => :private_func}))
  end
end
