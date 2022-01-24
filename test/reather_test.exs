defmodule ReatherTest do
  use ExUnit.Case
  use Reather

  defmodule Target do
    use Reather

    defmodule Impure do
      reather read("invalid") do
        Reather.left(:enoent)
      end

      reather read("valid") do
        Reather.right(99)
      end
    end

    reather read_and_multiply(filename) do
      input <- Impure.read(filename) |> Reather.inject()

      multiply(input)
    end

    reatherp multiply(input) do
      %{number: number} <- Reather.ask()

      Reather.right(input * number)
    end
  end

  test "Reather" do
    assert %Left{left: :enoent} = Target.read_and_multiply("invalid") |> Reather.run()
    assert %Right{right: 990} = Target.read_and_multiply("valid") |> Reather.run(%{number: 10})

    assert %Right{right: 880} =
             Target.read_and_multiply("valid")
             |> Reather.overlay(Reather.mock(%{&Target.Impure.read/1 => Reather.right(88)}))
             |> Reather.run(%{number: 10})
  end
end
