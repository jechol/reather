defmodule Defr.ImportTest do
  use ExUnit.Case, async: true
  use Defr
  alias Algae.Reader

  defmodule Target do
    use Defr

    import Enum, only: [at: 2]

    defr target(list, pos) do
      at(list, pos) |> inject()
    end
  end

  test "import" do
    assert 1 == Target.target([0, 1], 1) |> Reader.run(%{})
    assert 100 == Target.target([0, 1], 1) |> Reader.run(mock(%{&Enum.at/2 => 100}))
  end
end
