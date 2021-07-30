defmodule Defre.InjectTest do
  use ExUnit.Case, async: true
  require Defre.Inject
  alias Defre.Inject
  alias Defre.AST

  @config %{mode: {:reader, :either}, reader_modules: []}

  describe "inject_ast_recursively" do
    test "capture is not expanded" do
      blk =
        quote do
          &Calc.sum/2
        end

      {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__, @config)
      assert_inject(actual, {blk, [], []})
    end

    test "access is not expanded" do
      blk =
        quote do
          conn.assigns
        end

      {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__, @config)
      assert_inject(actual, {blk, [], []})
    end

    test ":erlang is not expanded" do
      blk =
        quote do
          :erlang.+(100, 200)
          Kernel.+(100, 200)
        end

      {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__, @config)
      assert_inject(actual, {blk, [], []})
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
              Map.get(deps, &Math.pow/2, :erlang.make_fun(Map.get(deps, Math, Math), :pow, 2)).(
                2,
                x
              )
          end
        end

      {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__, @config)
      assert_inject(actual, {exp_ast, [&Math.pow/2], [Math]})
    end

    test "direct import is not allowed" do
      blk =
        quote do
          import Calc

          sum(a, b)
        end

      {:error, :modifier} = Inject.inject_ast_recursively(blk, __ENV__, @config)
    end

    test "operator case 1" do
      blk =
        quote do
          Calc.to_int(a) >>> fn a_int -> Calc.to_int(b) >>> fn b_int -> a_int + b_int end end
        end

      exp_ast =
        quote do
          Map.get(deps, &Calc.to_int/1, :erlang.make_fun(Map.get(deps, Calc, Calc), :to_int, 1)).(
            a
          ) >>>
            fn a_int ->
              Map.get(
                deps,
                &Calc.to_int/1,
                :erlang.make_fun(Map.get(deps, Calc, Calc), :to_int, 1)
              ).(b) >>> fn b_int -> a_int + b_int end
            end
        end

      {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__, @config)
      assert_inject(actual, {exp_ast, [&Calc.to_int/1, &Calc.to_int/1], [Calc, Calc]})
    end

    test "operator case 2" do
      blk =
        quote do
          Calc.to_int(a) >>> fn a_int -> (fn b_int -> a_int + b_int end).(Calc.to_int(b)) end
        end

      exp_ast =
        quote do
          Map.get(deps, &Calc.to_int/1, :erlang.make_fun(Map.get(deps, Calc, Calc), :to_int, 1)).(
            a
          ) >>>
            fn a_int ->
              (fn b_int -> a_int + b_int end).(
                Map.get(
                  deps,
                  &Calc.to_int/1,
                  :erlang.make_fun(Map.get(deps, Calc, Calc), :to_int, 1)
                ).(b)
              )
            end
        end

      {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__, @config)
      assert_inject(actual, {exp_ast, [&Calc.to_int/1, &Calc.to_int/1], [Calc, Calc]})
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
            Map.get(deps, &Calc.id/1, :erlang.make_fun(Map.get(deps, Calc, Calc), :id, 1)).(:try)
          rescue
            e in ArithmeticError ->
              Map.get(deps, &Calc.id/1, :erlang.make_fun(Map.get(deps, Calc, Calc), :id, 1)).(e)
          catch
            :error, number ->
              Map.get(deps, &Calc.id/1, :erlang.make_fun(Map.get(deps, Calc, Calc), :id, 1)).(
                number
              )
          else
            x ->
              Map.get(deps, &Calc.id/1, :erlang.make_fun(Map.get(deps, Calc, Calc), :id, 1)).(
                :else
              )
          end
        end

      {:ok, actual} = Inject.inject_ast_recursively(blk, __ENV__, @config)

      assert_inject(
        actual,
        {exp_ast, [&Calc.id/1, &Calc.id/1, &Calc.id/1, &Calc.id/1], [Calc, Calc, Calc, Calc]}
      )
    end
  end

  describe "inject_function" do
    test "success case" do
      {:defre, _, [head, [do: blk]]} =
        quote do
          defre add(a, b) do
            case a do
              false -> Calc.sum(a, b)
              true -> Calc.macro_sum(a, b)
            end
          end
        end

      expected =
        quote do
          def add(a, b) do
            Witchcraft.Monad.monad %Reader{} do
              deps <- Algae.Reader.ask()

              Witchcraft.Monad.monad %Right{} do
                case a do
                  false ->
                    Map.get(
                      deps,
                      &Calc.sum/2,
                      :erlang.make_fun(Map.get(deps, Calc, Calc), :sum, 2)
                    ).(a, b)

                  true ->
                    import Calc
                    sum(a, b)
                end
              end
            end
          end
        end

      actual = Inject.inject_function(head, [do: blk], env_with_macros(), @config)
      assert Macro.to_string(actual) == Macro.to_string(expected)
    end

    test "Compile error case" do
      assert_raise CompileError, ~r(import/require/use), fn ->
        :code.priv_dir(:defre)
        |> Path.join("import_in_inject.ex")
        |> Code.eval_file()
      end
    end
  end

  defp env_with_macros do
    import Calc
    macro_sum(1, 2)
    __ENV__
  end

  defp assert_inject({ast, captures_ast, mods}, {exp_ast, exp_captures, exp_mods}) do
    assert Macro.to_string(ast) == Macro.to_string(exp_ast)
    assert captures_ast |> Enum.map(&AST.unquote_function_capture/1) == exp_captures
    assert mods == exp_mods
  end
end
