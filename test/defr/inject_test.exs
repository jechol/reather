defmodule Defr.InjectTest do
  use ExUnit.Case, async: true
  import AstAssertions
  require Defr.Inject
  alias Defr.Inject

  describe "inject_ast_recursively" do
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
  end

  describe "inject_function" do
    test "success case for public" do
      {:defr, _, [head, [do: blk]]} =
        quote do
          defr add(a, b) do
            case a do
              false -> Calc.sum(a, b)
              true -> Calc.macro_sum(a, b)
            end
          end
        end

      expected =
        quote do
          @defr_funs {:add, 2}
          def add(a, b) do
            use Witchcraft.Monad

            monad %Algae.Reader{} do
              deps <- Algae.Reader.ask()

              return(
                case a do
                  false ->
                    Defr.Runner.run({Calc, :sum, 2}, [a, b], deps)

                  true ->
                    import Calc
                    sum(a, b)
                end
              )
            end
          end
        end

      actual = Inject.inject_function(:def, head, [do: blk], env_with_macros())
      assert_inject(actual, expected)
    end

    test "success case for private" do
      {:defrp, _, [head, [do: blk]]} =
        quote do
          defrp add(a, b) do
            case a do
              false -> Calc.sum(a, b)
              true -> Calc.macro_sum(a, b)
            end
          end
        end

      expected =
        quote do
          defp add(a, b) do
            use Witchcraft.Monad

            monad %Algae.Reader{} do
              deps <- Algae.Reader.ask()

              return(
                case a do
                  false ->
                    Defr.Runner.run({Calc, :sum, 2}, [a, b], deps)

                  true ->
                    import Calc
                    sum(a, b)
                end
              )
            end
          end
        end

      actual = Inject.inject_function(:defp, head, [do: blk], env_with_macros())
      assert_inject(actual, expected)
    end

    test "Compile error case" do
      assert_raise CompileError, ~r(import/require/use), fn ->
        Path.expand("../support/import_in_inject.exs", __DIR__)
        |> Code.eval_file()
      end
    end
  end

  defp env_with_macros do
    import Calc
    macro_sum(1, 2)
    __ENV__
  end

  defp assert_inject(ast, exp_ast) do
    assert Macro.to_string(ast) == Macro.to_string(exp_ast)
  end
end
