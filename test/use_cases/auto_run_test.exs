defmodule Defr.AutoRunTest do
  use ExUnit.Case, async: true
  use Defr
  alias Algae.Reader

  defmodule Target do
    use Defr

    defr target(list, pos) do
      at(list, pos)
    end

    defr at(list, pos) do
      Enum.at(list, pos)
    end
  end

  test "auto run" do
    assert 1 == Target.target([0, 1], 1)
  end
end
