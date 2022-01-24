defmodule Reather.ReatherfyTest do
  use ExUnit.Case, async: false
  use Reather
  alias Reather.Macros

  describe "reatherfy" do
    test "multi line" do
      f =
        reatherfy(fn x, y ->
          let _ = Process.sleep(100)
          Right.new(x + y)
        end)

      assert %Right{right: 3} == f.(1, 2) |> Reather.run(%{})
    end

    test "multi clauses" do
      f =
        reatherfy(fn
          x, y when is_integer(x) ->
            z <- ask()
            Right.new(x + y + z)

          <<x>>, <<y>> ->
            <<z>> <- ask()
            Right.new(x + y + z)
        end)

      assert %Right{right: 6} == f.(1, 2) |> Reather.run(3)
      assert %Right{right: 6} == f.(<<1>>, <<2>>) |> Reather.run(<<3>>)
    end

    test "raw value" do
      g = reatherfy(fn _ -> Right.new([]) end)

      assert %Right{right: []} == g.(nil) |> Reather.run(nil)
    end
  end
end
