defmodule Defr.PrivateTest do
  use ExUnit.Case, async: true
  use Defr
  alias Algae.Reader

  defmodule Target do
    use Defr

    defr target(list, pos) do
      at(list, pos) |> inject()
    end

    defp at(list, pos) do
      Enum.at(list, pos)
    end
  end

  test "import" do
    assert 1 == Target.target([0, 1], 1) |> Reader.run(%{})
    assert 100 == Target.target([0, 1], 1) |> Reader.run(mock(%{&Target.at/2 => 100}))
  end
end
