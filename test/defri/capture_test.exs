defmodule Defr.CaptureTest do
  use ExUnit.Case, async: false
  use Defr
  alias Algae.Reader

  defmodule Target do
    use Defr

    defp local_first(list) do
      List.first(list)
    end

    defr external_capture() do
      :erlang.apply((&List.first/1) |> inject(), [[1, 2]])
    end

    defr local_capture() do
      :erlang.apply((&local_first/1) |> inject(), [[100, 200]])
    end
  end

  test "external" do
    assert 1 ==
             Target.external_capture() |> Reader.run(%{})

    assert :external ==
             Target.external_capture() |> Reader.run(mock(%{&List.first/1 => :external}))
  end

  test "local" do
    assert 100 ==
             Target.local_capture() |> Reader.run(%{})

    assert :local ==
             Target.local_capture() |> Reader.run(mock(%{&Target.local_first/1 => :local}))
  end
end
