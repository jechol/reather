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

  test "Reather.run" do
    assert %Left{left: :enoent} = Target.read_and_multiply("invalid") |> Reather.run()
    assert %Right{right: 990} = Target.read_and_multiply("valid") |> Reather.run(%{number: 10})
  end

  test "Reather.run with mock" do
    mock = Reather.mock(%{&Target.Impure.read/1 => Reather.right(88)})

    assert %Right{right: 880} =
             Target.read_and_multiply("valid")
             |> Reather.run(mock |> Map.merge(%{number: 10}))
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
    assert_raise RuntimeError, fn ->
      monad %Reather{} do
        return 10
      end
    end

    assert %Right{right: 3} ==
             (monad %Reather{} do
                let a = 1
                let b = 2
                return Right.new(a + b)
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
end
