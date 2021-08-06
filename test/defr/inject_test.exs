defmodule Defr.InjectTest do
  use ExUnit.Case, async: false
  use Defr
  alias Algae.Reader

  defmodule Target do
    use Defr

    import Enum, only: [at: 2]

    defr top(list, pos) do
      middle(list, pos) |> run()
    end

    defr middle(list, pos) do
      bottom(list, pos) |> inject() |> run()
    end

    defrp bottom(list, pos) do
      let _ = &at/2
      at(list, pos) |> inject()
    end
  end

  test "inject" do
    assert 1 == Target.top([0, 1], 1) |> Reader.run(%{})

    assert :imported_func ==
             Target.top([0, 1], 1) |> Reader.run(mock(%{&Enum.at/2 => :imported_func}))

    assert :private_func ==
             Target.top([0, 1], 1)
             |> Reader.run(mock(%{&Target.bottom/2 => :private_func}))
  end
end
