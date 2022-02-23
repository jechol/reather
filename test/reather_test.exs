defmodule ReatherTest do
  use ExUnit.Case
  use Reather

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

  reather sum(aa, bb, cc) do
    a <- aa
    b <- bb
    c <- cc
    d <- Reather.ask()

    a + b + c + d
  end

  test "function as reather" do
    assert %Right{right: 10} ==
             sum(1, Right.new(2), Reather.new(fn _ -> Right.new(3) end)) |> Reather.run(4)
  end

  describe "reather/1" do
    test "for success" do
      assert %Right{right: 15} ==
               (reather do
                  a <- Right.new(1)
                  b <- Reather.new(fn _ -> Right.new(2) end)
                  c <- return 3
                  d <- return %Right{right: 4}
                  e <- Reather.ask()
                  let sum = a + b + c + d + e

                  sum
                end)
               |> Reather.run(5)

      assert %Right{right: 1} ==
               (reather do
                  1
                end)
               |> Reather.run()
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

    test "for do: " do
      assert %Right{right: 10} == reather(do: 10) |> Reather.run()
      assert %Right{right: nil} == reather(do: nil) |> Reather.run()
    end
  end
end
