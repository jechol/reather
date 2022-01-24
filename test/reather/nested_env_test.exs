defmodule Reather.NestedEnvTest do
  use ExUnit.Case, async: false
  use Reather

  defmodule Target do
    use Reather

    reather top(value) do
      middle() |> run(%{value: {:env, value}})
    end

    reather middle() do
      bottom() |> run()
    end

    reatherp bottom() do
      %{value: {source, value}} <- ask()
      {source, value} |> Right.new()
    end
  end

  test "outer env has higher priority" do
    assert %Right{right: {:env, 10}} = Target.top(10) |> Reather.run(%{})
    assert %Right{right: {:mock, 20}} = Target.top(10) |> Reather.run(%{value: {:mock, 20}})
  end
end
