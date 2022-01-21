defmodule Defri.AskTest do
  use ExUnit.Case, async: false
  use Defri
  alias Defri.Rither

  defmodule Target do
    use Defri

    defri single() do
      1 + 1
    end

    defri multi() do
      %{a: a} <- ask()
      %{b: b} <- ask()
      1 + a + b
    end
  end

  test "single" do
    assert 2 == Target.single() |> Rither.run(%{})
  end

  test "multi" do
    assert 111 == Target.multi() |> Rither.run(%{a: 10, b: 100})
  end
end
