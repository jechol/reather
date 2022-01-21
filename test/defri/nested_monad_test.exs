defmodule Defri.NestedMonadTest do
  use ExUnit.Case, async: false
  use Defri
  alias Defri.Rither
  alias Algae.Either.Right

  defmodule Target do
    use Defri

    defr target() do
      let _ = Process.sleep(100)

      chain do
        n <- get_number() |> inject()
        n
      end
    end

    def get_number(), do: Right.new(1)
  end

  test "witchcraft" do
    assert 1 == Target.target() |> Rither.run(%{})
    assert 100 == Target.target() |> Rither.run(mock(%{&Target.get_number/0 => Right.new(100)}))
  end
end
