defmodule ReatherTest do
  use ExUnit.Case

  use Reather

  test "Reather" do
    sum =
      monad %Reather{} do
        %{a: a, b: b, fail: fail} <- Reather.ask()

        if fail do
          Reather.left(:sum_error)
        else
          # Same with Reather.right(a + b)
          return Right.new(a + b)
        end
      end

    assert %Left{left: :sum_error} == sum |> Reather.run(%{a: 1, b: 2, fail: true})
    assert %Right{right: 3} == sum |> Reather.run(%{a: 1, b: 2, fail: false})
  end
end
