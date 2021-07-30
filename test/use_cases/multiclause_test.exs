defmodule Defr.MulticlauseTest do
  use ExUnit.Case, async: true
  alias Algae.Reader
  use Defr

  defmodule Multi do
    defr(add(a, 0), do: Calc.id(a))
    defr(add(a, b), do: Calc.sum(a, b))
  end

  test "Multiclause with pattern matching works" do
    assert Multi.add(10, 0) |> Reader.run(%{}) == 10
    assert Multi.add(10, 0) |> Reader.run(mock(%{&Calc.id/1 => 99})) == 99

    assert Multi.add(10, 1) |> Reader.run(%{}) == 11
    assert Multi.add(10, 1) |> Reader.run(mock(%{&Calc.sum/2 => 99})) == 99
  end
end
