defmodule Defri.DupUseTest do
  use ExUnit.Case, async: false
  use Defri

  defmodule Target do
    use Defri
    use Defri
  end
end
