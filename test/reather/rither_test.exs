defmodule Rither.RitherTest do
  use ExUnit.Case

  use Witchcraft
  alias Algae.Either.{Left, Right}
  alias Reather.Rither

  test "Rither" do
    sum =
      monad %Rither{} do
        %{a: a, b: b, fail: fail} <- Rither.ask()

        if fail do
          Rither.left(:sum_error)
        else
          # Same with Rither.right(a + b)
          return(Right.new(a + b))
        end
      end

    assert %Left{left: :sum_error} == sum |> Rither.run(%{a: 1, b: 2, fail: true})
    assert %Right{right: 3} == sum |> Rither.run(%{a: 1, b: 2, fail: false})
  end
end
