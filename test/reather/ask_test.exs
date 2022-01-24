defmodule Reather.AskTest do
  use ExUnit.Case, async: false
  use Reather

  defmodule Target do
    use Reather

    reather single() do
      Right.new(1 + 1)
    end

    reather multi() do
      %{a: a} <- ask()
      %{b: b} <- ask()
      Right.new(1 + a + b)
    end
  end

  test "single" do
    assert %Right{right: 2} == Target.single() |> Reather.run(%{})
  end

  test "multi" do
    assert %Right{right: 111} == Target.multi() |> Reather.run(%{a: 10, b: 100})
  end
end
