defmodule Defr.WitchcraftTest do
  use ExUnit.Case, async: false
  use Defr
  alias Algae.Reader

  defmodule Target do
    use Defr

    defr target() do
      chain do
        n <- get_number()
      end
    end

    defp get_number(), do: Right.new(100)
  end

  test "witchcraft" do
    assert 1 == Target.target() |> Reader.run(%{})
  end
end
