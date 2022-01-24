defmodule Reather.NestedMonadTest do
  use ExUnit.Case, async: false
  use Reather

  defmodule Target do
    use Reather

    reather target() do
      let _ = Process.sleep(100)

      return (monad %Right{} do
                n <- get_number() |> Reather.inject()
                n |> Right.new()
              end)
    end

    def get_number(), do: Right.new(1)
  end

  test "witchcraft" do
    assert %Right{right: 1} == Target.target() |> Reather.run(%{})

    assert %Right{right: 100} ==
             Target.target()
             |> Reather.run(Reather.mock(%{&Target.get_number/0 => Right.new(100)}))
  end
end
