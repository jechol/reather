defmodule Defr.NestedEnvTest do
  use ExUnit.Case, async: false
  use Defr
  alias Algae.Reader

  defmodule Target do
    use Defr

    defr top(value) do
      middle() |> run(%{value: {:env, value}})
    end

    defr middle() do
      bottom() |> run()
    end

    defrp bottom() do
      %{value: {source, value}} <- ask()
      {source, value}
    end
  end

  test "outer env has higher priority" do
    assert {:env, 10} = Target.top(10) |> Reader.run(%{})
    assert {:mock, 20} = Target.top(10) |> Reader.run(%{value: {:mock, 20}})
  end
end
