defmodule Defr.NestedMonadTest do
  use ExUnit.Case, async: false
  use Defr
  alias Algae.Reader
  alias Algae.Either.Right

  defmodule Target do
    use Defr

    defr target() do
      monad %Right{} do
        n <- get_number() |> inject()
        n
      end
    end

    def get_number(), do: Right.new(1)
  end

  test "witchcraft" do
    assert 1 == Target.target() |> Reader.run(%{})
    assert 100 == Target.target() |> Reader.run(mock(%{&Target.get_number/0 => Right.new(100)}))
  end
end
