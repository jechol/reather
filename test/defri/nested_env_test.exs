defmodule Defri.NestedEnvTest do
  use ExUnit.Case, async: false
  use Defri
  alias Defri.Rither

  defmodule Target do
    use Defri

    defri top(value) do
      middle() |> run(%{value: {:env, value}})
    end

    defri middle() do
      bottom() |> run()
    end

    defrip bottom() do
      %{value: {source, value}} <- ask()
      {source, value} |> Right.new()
    end
  end

  test "outer env has higher priority" do
    assert %Right{right: {:env, 10}} = Target.top(10) |> Rither.run(%{})
    assert %Right{right: {:mock, 20}} = Target.top(10) |> Rither.run(%{value: {:mock, 20}})
  end
end
