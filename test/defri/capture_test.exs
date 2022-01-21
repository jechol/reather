defmodule Defri.CaptureTest do
  use ExUnit.Case, async: false
  use Defri
  alias Defri.Rither

  defmodule Target do
    use Defri

    defp local_first(list) do
      List.first(list)
    end

    defri external_capture() do
      :erlang.apply((&List.first/1) |> inject(), [[1, 2]])
    end

    defri local_capture() do
      :erlang.apply((&local_first/1) |> inject(), [[100, 200]])
    end
  end

  test "external" do
    assert 1 ==
             Target.external_capture() |> Rither.run(%{})

    assert :external ==
             Target.external_capture() |> Rither.run(mock(%{&List.first/1 => :external}))
  end

  test "local" do
    assert 100 ==
             Target.local_capture() |> Rither.run(%{})

    assert :local ==
             Target.local_capture() |> Rither.run(mock(%{&Target.local_first/1 => :local}))
  end
end
