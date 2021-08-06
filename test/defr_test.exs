defmodule DefrTest do
  use ExUnit.Case, async: true
  use Defr
  alias Algae.Reader

  defmodule ExprSubject do
    use Defr

    defr single() do
      1 + 1
    end

    defr multi() do
      %{a: a} <- ask()
      %{b: b} <- ask()
      1 + a + b
    end
  end

  test "single" do
    assert 2 == ExprSubject.single() |> Reader.run(%{})
  end

  test "multi" do
    assert 111 == ExprSubject.multi() |> Reader.run(%{a: 10, b: 100})
  end

  defmodule Target do
    use Defr

    import Enum, only: [at: 2]

    defr top(list, pos) do
      middle(list, pos) |> run()
    end

    defr middle(list, pos) do
      bottom(list, pos) |> inject() |> run()
    end

    defrp bottom(list, pos) do
      at(list, pos) |> inject()
    end
  end

  test "import" do
    assert 1 == Target.top([0, 1], 1) |> Reader.run(%{})

    assert :imported_func ==
             Target.top([0, 1], 1) |> Reader.run(mock(%{&Enum.at/2 => :imported_func}))

    assert :private_func ==
             Target.top([0, 1], 1)
             |> Reader.run(mock(%{&Target.bottom/2 => :private_func}))
  end

  defmodule MockSubject do
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
      m = mock(%{&MockSubject.sum/2 => 99})

      f_sum = m[&MockSubject.sum/2]

      assert :erlang.fun_info(f_sum)[:arity] == 2

      assert %Reader{} = f_sum.(10, 20)
      assert 99 == f_sum.(10, 20) |> Reader.run(%{})
    end
  end
end
