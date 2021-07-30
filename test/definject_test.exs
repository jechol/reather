defmodule DefreTest do
  use ExUnit.Case, async: true
  use Defre

  defmodule Nested do
    defmodule DoubleNested do
      defdelegate to_int(str), to: String, as: :to_integer
      defdelegate to_atom(str), to: String, as: :to_atom
    end
  end

  alias Nested.DoubleNested

  describe "defre" do
    def quack(), do: nil

    defmodule Foo do
      import List, only: [first: 1]
      require Calc

      def quack(), do: :arity_0_quack
      def quack(_), do: :arity_1_quack

      def id(v), do: v

      defre bar(type) when is_atom(type) do
        case type do
          # Remote
          :mod -> __MODULE__.quack()
          :remote -> Enum.count([1, 2])
          :nested_remote -> {DoubleNested.to_int("99"), DoubleNested.to_atom("hello")}
          :pipe -> "1" |> Foo.id()
          :macro -> Calc.macro_sum(10, 20)
          :capture -> &Calc.sum/2
          :kernel_plus -> Kernel.+(1, 10)
          :string_to_atom -> "foobar" |> String.to_atom()
          :string_to_integer -> "100" |> String.to_integer()
          # Local, Import
          :local -> quack()
          :import -> first([10, 20])
          :anonymous_fun -> [1, 2] |> Enum.map(&Calc.id(&1))
          :string_concat -> "#{[1, 2] |> Enum.map(&"*#{&1}*") |> Enum.join()}"
        end
        |> Right.new()
      end

      defre hash(<<data::binary>>) do
        :crypto.hash(:md5, <<data::binary>>) |> Right.new()
      end
    end

    test "original works" do
      assert Foo.bar(:mod) |> Reader.run(%{}) == :arity_0_quack |> Right.new()
      assert Foo.bar(:remote) |> Reader.run(%{}) == 2 |> Right.new()
      assert Foo.bar(:nested_remote) |> Reader.run(%{}) == {99, :hello} |> Right.new()
      assert Foo.bar(:pipe) |> Reader.run(%{}) == "1" |> Right.new()
      assert Foo.bar(:macro) |> Reader.run(%{}) == 30 |> Right.new()
      assert (Foo.bar(:capture) |> Reader.run(%{})).right.(20, 40) == 60
      assert Foo.bar(:kernel_plus) |> Reader.run(%{}) == 11 |> Right.new()
      assert Foo.bar(:string_to_atom) |> Reader.run(%{}) == :foobar |> Right.new()
      assert Foo.bar(:string_to_integer) |> Reader.run(%{}) == 100 |> Right.new()

      assert Foo.bar(:local) |> Reader.run(%{}) == :arity_0_quack |> Right.new()
      assert Foo.bar(:import) |> Reader.run(%{}) == 10 |> Right.new()
      assert Foo.bar(:anonymous_fun) |> Reader.run(%{}) == [1, 2] |> Right.new()
      assert Foo.bar(:string_concat) |> Reader.run(%{}) == "*1**2*" |> Right.new()

      assert Foo.hash("hello") |> Reader.run(%{}) ==
               <<93, 65, 64, 42, 188, 75, 42, 118, 185, 113, 157, 145, 16, 23, 197, 146>>
               |> Right.new()
    end

    defmodule Baz do
      def quack, do: "baz quack"
      def to_int(_), do: "baz to_int"
      def to_atom(_), do: "baz to_atom"
    end

    test "working case" do
      assert Foo.bar(:mod) |> Reader.run(%{&Foo.quack/0 => fn -> :injected end}) ==
               :injected |> Right.new()

      assert Foo.bar(:remote) |> Reader.run(%{&Enum.count/1 => fn _ -> 9999 end}) ==
               9999 |> Right.new()

      assert Foo.bar(:nested_remote)
             |> Reader.run(%{
               &DoubleNested.to_int/1 => &Baz.to_int/1,
               &DoubleNested.to_atom/1 => &Baz.to_atom/1
             }) == {"baz to_int", "baz to_atom"} |> Right.new()

      assert Foo.bar(:nested_remote)
             |> Reader.run(mock(%{&DoubleNested.to_atom/1 => :mocked})) ==
               {99, :mocked} |> Right.new()

      assert Foo.bar(:pipe)
             |> Reader.run(%{&Foo.id/1 => fn _ -> "100" end, &Enum.count/1 => fn _ -> 9999 end}) ==
               "100" |> Right.new()

      assert Foo.bar(:macro) |> Reader.run(%{&Calc.sum/2 => fn _, _ -> 999 end, strict: false}) ==
               30 |> Right.new()

      assert Foo.bar(:string_to_atom) |> Reader.run(%{&String.to_atom/1 => fn _ -> :injected end}) ==
               :injected |> Right.new()

      assert Foo.hash("hello") |> Reader.run(%{&:crypto.hash/2 => fn _, _ -> :world end}) ==
               :world |> Right.new()
    end
  end

  test "mock" do
    m = mock(%{&Enum.count/1 => (fn -> 100 end).(), &Enum.map/2 => 200, strict: false})

    assert m[:strict] == false

    f1 = m[&Enum.count/1]
    f2 = m[&Enum.map/2]

    assert :erlang.fun_info(f1)[:arity] == 1
    assert :erlang.fun_info(f2)[:arity] == 2

    assert f1.(nil) == 100
    assert f2.(nil, nil) == 200
  end
end
