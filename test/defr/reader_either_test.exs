defmodule Defr.ReaderEitherTest do
  use ExUnit.Case, async: false
  use Defr
  alias Algae.Reader
  alias Algae.Either.{Left, Right}

  defmodule Target do
    use Defr

    defr div_10_by(divisor) do
      chain do
        :ok <-
          case divisor do
            0 -> Left.new(:div_by_zero)
            _ -> Right.new(:ok)
          end

        Right.new(10 / divisor)
      end
      |> case do
        %Left{left: :div_by_zero} -> Right.new(-1)
        %Right{} = r -> r
      end
    end
  end

  test "Reader - Either" do
    assert %Right{right: 5.0} == Target.div_10_by(2) |> Reader.run(%{})
    assert %Right{right: -1} == Target.div_10_by(0) |> Reader.run(%{})
  end
end
