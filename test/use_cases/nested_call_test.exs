defmodule Defre.NestedCallTest do
  use ExUnit.Case, async: true
  use Witchcraft, override_kernel: false
  use Defre
  alias Algae.Either.Right
  alias Algae.Reader

  defmodule User do
    defstruct [:id, :src]

    defre get_src() do
      :db
    end

    defre get_by_id(user_id) do
      %__MODULE__{id: user_id, src: __MODULE__.get_src()} |> Right.new()
    end
  end

  defmodule Accounts do
    defre get_user_by_id(user_id) do
      User.get_by_id(user_id)
    end
  end

  defmodule UserController do
    defre profile_re(user_id) do
      %User{id: id, src: src} <- Accounts.get_user_by_id(user_id)
      "id: #{id}, src: #{src}" |> Right.new()
    end
  end

  test "profile_re" do
    assert %Right{right: "id: 1, src: db"} == UserController.profile_re(1) |> Reader.run(%{})
  end
end
