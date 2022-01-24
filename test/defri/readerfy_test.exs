defmodule Reather.ReaderfyTest do
  use ExUnit.Case, async: false
  use Reather
  alias Reather.Rither

  describe "readerfy" do
    test "multi line" do
      f =
        readerfy(fn x, y ->
          let _ = Process.sleep(100)
          x + y
        end)

      assert 3 == f.(1, 2) |> Rither.run(%{})
    end

    test "multi clauses" do
      f =
        readerfy(fn
          x, y when is_integer(x) ->
            z <- ask()
            x + y + z

          <<x>>, <<y>> ->
            <<z>> <- ask()
            x + y + z
        end)

      assert 6 == f.(1, 2) |> Rither.run(3)
      assert 6 == f.(<<1>>, <<2>>) |> Rither.run(<<3>>)
    end

    test "raw value" do
      g = readerfy(fn _ -> [] end)

      assert [] == g.(nil) |> Rither.run(nil)
    end
  end
end
