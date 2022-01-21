defmodule Defr.DupUseTest do
  use ExUnit.Case, async: false
  use Defr

  defmodule Target do
    use Defr
    use Defr
  end
end
