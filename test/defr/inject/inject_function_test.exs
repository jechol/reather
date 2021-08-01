defmodule Defr.Inject.InjectFunctionTest do
  use ExUnit.Case, async: true
  require Defr.Inject
  alias Defr.Inject

  test "success case for public" do
    {:defr, _, [head, body]} =
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

    actual = Inject.inject_function(:def, head, body, env_with_macros())
    assert Macro.to_string(expected) == Macro.to_string(actual)
  end

  test "modifier is not allowed" do
    assert_raise CompileError, ~r(import/require/use), fn ->
      Path.expand("../../support/import_in_inject.exs", __DIR__)
      |> Code.eval_file()
    end
  end

  defp env_with_macros do
    import Calc
    __ENV__
  end
end
