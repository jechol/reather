defmodule Reather.MockTest do
  use ExUnit.Case, async: false
  use Reather

  defmodule Target do
    use Reather

    reather sum(a, b), do: a + b
  end

  describe "mock" do
    test "non-reader" do
      m = mock(%{&Enum.count/1 => (fn -> Right.new(100) end).(), &Enum.map/2 => Right.new(200)})

      f1 = m[&Enum.count/1]
      f2 = m[&Enum.map/2]

      assert :erlang.fun_info(f1)[:arity] == 1
      assert :erlang.fun_info(f2)[:arity] == 2

      assert f1.(nil) == Right.new(100)
      assert f2.(nil, nil) == Right.new(200)
    end

    test "reader" do
      m = mock(%{&Target.sum/2 => Right.new(99)})

      f_sum = m[&Target.sum/2]

      assert :erlang.fun_info(f_sum)[:arity] == 2

      assert %Reather{} = f_sum.(10, 20)
      assert Right.new(99) == f_sum.(10, 20) |> Reather.run(%{})
    end
  end
end
