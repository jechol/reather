defmodule Defr.Inject.InjectAstRecursivelyTest do
  use ExUnit.Case, async: true
  import AstAssertions
  require Defr.Inject
  alias Defr.Inject

  test "capture is not expanded" do
    blk =
      quote do
        &Calc.sum/2
      end

    {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__)
    assert_ast blk == actual
  end

  test "access is not expanded" do
    blk =
      quote do
        conn.assigns
      end

    {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__)
    assert_ast blk == actual
  end

  test ":erlang is not expanded" do
    blk =
      quote do
        :erlang.+(100, 200)
        Kernel.+(100, 200)
      end

    {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__)
    assert_ast blk == actual
  end

  test "indirect import is allowed" do
    require Calc

    blk =
      quote do
        &Calc.sum/2
        Calc.macro_sum(10, 20)

        case 1 == 1 do
          x when x == true -> Math.pow(2, x)
        end
      end

    exp_ast =
      quote do
        &Calc.sum/2

        (
          import(Calc)
          sum(10, 20)
        )

        case 1 == 1 do
          x when x == true ->
            Defr.Runner.run({Math, :pow, 2}, [2, x], deps)
        end
      end

    {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__)
    assert_inject(actual, exp_ast)
  end

  test "direct import is not allowed" do
    blk =
      quote do
        import Calc

        sum(a, b)
      end

    {:error, :modifier} = Inject.inject_ast_recursively(blk, __ENV__)
  end

  test "operator case 1" do
    blk =
      quote do
        Calc.to_int(a) >>> fn a_int -> Calc.to_int(b) >>> fn b_int -> a_int + b_int end end
      end

    exp_ast =
      quote do
        Defr.Runner.run({Calc, :to_int, 1}, [a], deps) >>>
          fn a_int ->
            Defr.Runner.run({Calc, :to_int, 1}, [b], deps) >>> fn b_int -> a_int + b_int end
          end
      end

    {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__)
    assert_inject(actual, exp_ast)
  end

  test "operator case 2" do
    blk =
      quote do
        Calc.to_int(a) >>> fn a_int -> (fn b_int -> a_int + b_int end).(Calc.to_int(b)) end
      end

    exp_ast =
      quote do
        Defr.Runner.run({Calc, :to_int, 1}, [a], deps) >>>
          fn a_int ->
            (fn b_int -> a_int + b_int end).(Defr.Runner.run({Calc, :to_int, 1}, [b], deps))
          end
      end

    {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__)
    assert_inject(actual, exp_ast)
  end

  test "try case 1" do
    blk =
      quote do
        try do
          Calc.id(:try)
        else
          x -> Calc.id(:else)
        rescue
          e in ArithmeticError -> Calc.id(e)
        catch
          :error, number -> Calc.id(number)
        end
      end

    exp_ast =
      quote do
        try do
          Defr.Runner.run({Calc, :id, 1}, [:try], deps)
        rescue
          e in ArithmeticError ->
            Defr.Runner.run({Calc, :id, 1}, [e], deps)
        catch
          :error, number ->
            Defr.Runner.run({Calc, :id, 1}, [number], deps)
        else
          x ->
            Defr.Runner.run({Calc, :id, 1}, [:else], deps)
        end
      end

    {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__)
    assert_inject(actual, exp_ast)
  end

  defp assert_inject(ast, exp_ast) do
    assert Macro.to_string(ast) == Macro.to_string(exp_ast)
  end
end
