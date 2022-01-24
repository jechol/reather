defmodule Reather.CaptureTest do
  use ExUnit.Case, async: false
  use Reather
  alias Reather.Macros

  defmodule Target do
    use Reather

    defp local_first(list) do
      List.first(list)
    end

    reather external_capture() do
      :erlang.apply((&List.first/1) |> inject(), [[1, 2]]) |> Right.new()
    end

    reather local_capture() do
      :erlang.apply((&local_first/1) |> inject(), [[100, 200]]) |> Right.new()
    end
  end

  test "external" do
    assert %Right{right: 1} ==
             Target.external_capture() |> Reather.run(%{})

    assert %Right{right: :external} ==
             Target.external_capture()
             |> Reather.run(mock(%{&List.first/1 => :external}))
  end

  test "local" do
    assert %Right{right: 100} ==
             Target.local_capture() |> Reather.run(%{})

    assert %Right{right: :local} ==
             Target.local_capture() |> Reather.run(mock(%{&Target.local_first/1 => :local}))
  end
end
