defmodule Reather.OverlayTest do
  use ExUnit.Case, async: false
  use Reather

  defmodule Target do
    use Reather

    reather top(value) do
      middle() |> Reather.overlay(%{value: {:overlay, value}})
    end

    reather middle() do
      bottom()
    end

    reatherp bottom() do
      %{value: {source, value}} <- Reather.ask()
      return {source, value} |> Right.new()
    end
  end

  test "outer env has higher priority" do
    assert %Right{right: {:overlay, 10}} = Target.top(10) |> Reather.run(%{value: {:mock, 20}})
  end
end
