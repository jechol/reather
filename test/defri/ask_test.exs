defmodule Defri.AskTest do
  use ExUnit.Case, async: false
  use Defri
  alias Defri.Rither

  defmodule Target do
    use Defri

    defri single() do
      Right.new(1 + 1)
    end

    defri multi() do
      %{a: a} <- ask()
      %{b: b} <- ask()
      Right.new(1 + a + b)
    end
  end

  test "single" do
    assert %Right{right: 2} == Target.single() |> Rither.run(%{})
  end

  test "multi" do
    assert %Right{right: 111} == Target.multi() |> Rither.run(%{a: 10, b: 100})
  end
end
