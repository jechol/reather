defmodule Reather.ReatherfyTest do
  use ExUnit.Case, async: false
  use Reather

  describe "reatherfy" do
    test "multi line" do
      f =
        Reather.reatherfy(fn x, y ->
          let _ = Process.sleep(100)
          return Right.new(x + y)
        end)

      assert %Right{right: 3} == f.(1, 2) |> Reather.run(%{})
    end

    test "multi clauses" do
      f =
        Reather.reatherfy(fn
          x, y when is_integer(x) ->
            z <- Reather.ask()
            return Right.new(x + y + z)

          <<x>>, <<y>> ->
            <<z>> <- Reather.ask()
            return Right.new(x + y + z)
        end)

      assert %Right{right: 6} == f.(1, 2) |> Reather.run(3)
      assert %Right{right: 6} == f.(<<1>>, <<2>>) |> Reather.run(<<3>>)
    end

    test "raw value" do
      g = Reather.reatherfy(fn _ -> return Right.new([]) end)

      assert %Right{right: []} == g.(nil) |> Reather.run(nil)
    end
  end
end
