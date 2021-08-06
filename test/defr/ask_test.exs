defmodule Defr.AskTest do
  use ExUnit.Case, async: false
  use Defr
  alias Algae.Reader

  defmodule Target do
    use Defr

    defr single() do
      1 + 1
    end

    defr multi() do
      %{a: a} <- ask()
      %{b: b} <- ask()
      1 + a + b
    end
  end

  test "single" do
    assert 2 == Target.single() |> Reader.run(%{})
  end

  test "multi" do
    assert 111 == Target.multi() |> Reader.run(%{a: 10, b: 100})
  end
end
