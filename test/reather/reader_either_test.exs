defmodule Reather.ReaderEitherTest do
  use ExUnit.Case, async: false
  use Reather
  alias Reather.Rither
  alias Algae.Either.{Left, Right}

  defmodule Target do
    use Reather

    reather do_div(a, b) do
      Right.new(a / b)
    end

    reather div_10_by(divisor) do
      chain do
        :ok <-
          case divisor do
            0 -> Left.new(:div_by_zero)
            _ -> Right.new(:ok)
          end

        result <- do_div(10, divisor) |> run()

        result |> Right.new()
      end
      |> case do
        %Left{left: :div_by_zero} -> Right.new(-1)
        %Right{} = r -> r
      end
    end
  end

  test "Rither - Either" do
    assert %Right{right: 5.0} == Target.div_10_by(2) |> Rither.run(%{})
    assert %Right{right: -1} == Target.div_10_by(0) |> Rither.run(%{})
  end
end
