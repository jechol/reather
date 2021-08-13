defmodule Defr.CaptureTest do
  use ExUnit.Case, async: false
  use Defr
  alias Algae.Reader

  defmodule Target do
    use Defr

    import Enum, only: [at: 2]

    defr external_capture() do
      :erlang.apply((&List.first/1) |> inject(), [1, 2])
    end

    defr local_capture() do
      :erlang.apply((&local_first/1) |> inject(), [100, 200])
    end

    def local_first(list) do
      List.first(list)
    end
  end

  test "capture" do
    assert :external ==
             Target.external_capture() |> Reader.run(mock(%{&List.first/1 => :external}))

    assert :local ==
             Target.local_capture() |> Reader.run(mock(%{&Target.local_first/1 => :local}))
  end
end
