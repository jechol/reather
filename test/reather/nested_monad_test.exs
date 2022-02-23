defmodule Reather.NestedMonadTest do
  use ExUnit.Case, async: false
  use Reather

  defmodule Target do
    use Reather

    reather target() do
      env <- Reather.ask()
      let _ = Process.sleep(100)

      return (monad %Right{} do
                n <- Map.get(env, &Target.get_number/0, &get_number/0).()
                n |> Right.new()
              end)
    end

    def get_number(), do: Right.new(1)
  end

  test "witchcraft" do
    assert %Right{right: 1} == Target.target() |> Reather.run(%{})

    assert %Right{right: 100} ==
             Target.target()
             |> Reather.run(%{&Target.get_number/0 => fn -> Right.new(100) end})
  end
end
