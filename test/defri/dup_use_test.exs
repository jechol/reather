defmodule Reather.DupUseTest do
  use ExUnit.Case, async: false
  use Reather

  defmodule Target do
    use Reather
    use Reather
  end
end
