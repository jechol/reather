defmodule ReatherTest do
  use ExUnit.Case
  use Reather

  defmodule Target do
    use Reather

    defmodule Impure do
      reather read("invalid") do
        return Left.new(:enoent)
      end

      reather read("valid") do
        return Right.new(99)
      end
    end

    reather read_and_multiply(filename) do
      input <- Impure.read(filename) |> Reather.inject()

      multiply(input)
    end

    reatherp multiply(input) do
      %{number: number} <- Reather.ask()

      return Right.new(input * number)
    end
  end

  test "Reather.run with mock" do
    mock = Reather.mock(%{&Target.Impure.read/1 => Right.new(77)})
    # Same with
    # mock = Reather.mock(%{&Target.Impure.read/1 => Reather.new(fn _env -> Right.new(77) end)})

    assert %Left{left: :enoent} =
             Target.read_and_multiply("invalid") |> Reather.run(%{number: 10})

    assert %Right{right: 770} =
             Target.read_and_multiply("invalid") |> Reather.run(%{number: 10} |> Map.merge(mock))

    assert %Right{right: 990} = Target.read_and_multiply("valid") |> Reather.run(%{number: 10})
  end

  test "Functor" do
    assert_raise RuntimeError, fn ->
      Reather.new(fn _ -> 10 end) |> Functor.map(fn x -> x * 2 end) |> Reather.run()
    end

    assert %Right{right: 20} ==
             Reather.new(fn _ -> Right.new(10) end)
             |> Functor.map(fn x -> x * 2 end)
             |> Reather.run()
  end

  test "Applicative" do
    assert %Right{right: 3} ==
             (monad %Reather{} do
                let a = 1
                let b = 2
                return Right.new(a + b)
              end)
             |> Reather.run()

    assert %Right{right: 3} ==
             (monad %Reather{} do
                let a = 1
                let b = 2
                return a + b
              end)
             |> Reather.run()
  end

  test "Chain" do
    origin =
      monad %Reather{} do
        %{a: a} <- Reather.ask()
        return Right.new(a * 2)
      end

    new =
      monad %Reather{} do
        b <- origin
        return Right.new(b + 1)
      end

    assert %Right{right: 21} == new |> Reather.run(%{a: 10})
  end

  describe "reather/1" do
    test "for success" do
      result =
        reather do
          a <- Right.new(1)
          b <- Reather.new(fn _ -> Right.new(2) end)
          c <- return 3
          d <- return %Right{right: 4}

          return a + b + c + d
        end

      assert %Right{right: 10} == result |> Reather.run()
    end

    test "for failure" do
      assert %Left{left: 1} ==
               (reather do
                  a <- Left.new(1)
                  b <- return Right.new(2)

                  return a + b
                end)
               |> Reather.run()

      assert %Left{left: 2} ==
               (reather do
                  a <- Right.new(1)
                  b <- return Left.new(2)

                  return a + b
                end)
               |> Reather.run()
    end
  end
end
