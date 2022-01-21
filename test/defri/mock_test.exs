defmodule Defr.MockTest do
  use ExUnit.Case, async: false
  use Defr
  alias Algae.Reader

  defmodule Target do
    use Defr

    defr sum(a, b), do: a + b
  end

  describe "mock" do
    test "non-reader" do
      m = mock(%{&Enum.count/1 => (fn -> 100 end).(), &Enum.map/2 => 200})

      f1 = m[&Enum.count/1]
      f2 = m[&Enum.map/2]

      assert :erlang.fun_info(f1)[:arity] == 1
      assert :erlang.fun_info(f2)[:arity] == 2

      assert f1.(nil) == 100
      assert f2.(nil, nil) == 200
    end

    test "reader" do
      m = mock(%{&Target.sum/2 => 99})

      f_sum = m[&Target.sum/2]

      assert :erlang.fun_info(f_sum)[:arity] == 2

      assert %Reader{} = f_sum.(10, 20)
      assert 99 == f_sum.(10, 20) |> Reader.run(%{})
    end
  end
end
