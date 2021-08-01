defmodule AstAssertions do
  import ExUnit.Assertions

  defmacro assert_ast({:==, _, [expected, actual]}) do
    quote do
      assert Macro.to_string(unquote(expected)) == Macro.to_string(unquote(actual))
    end
  end
end
