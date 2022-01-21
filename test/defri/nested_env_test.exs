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

    defrp bottom() do
      %{value: {source, value}} <- ask()
      {source, value}
    end
  end

  test "outer env has higher priority" do
    assert {:env, 10} = Target.top(10) |> Rither.run(%{})
    assert {:mock, 20} = Target.top(10) |> Rither.run(%{value: {:mock, 20}})
  end
end
