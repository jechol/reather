defmodule Defr.ReaderfyTest do
  use ExUnit.Case, async: false
  use Defr
  alias Algae.Reader

  test "readerfy" do
    f =
      readerfy(fn
        x, y when is_integer(x) ->
          z <- ask()
          x + y + z

        <<x>>, <<y>> ->
          <<z>> <- ask()
          x + y + z
      end)

    assert 6 == f.(1, 2) |> Reader.run(3)
    assert 6 == f.(<<1>>, <<2>>) |> Reader.run(<<3>>)
  end
end
