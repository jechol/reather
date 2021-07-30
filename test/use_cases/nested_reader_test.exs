defmodule Defr.NestedCallTest do
  use ExUnit.Case, async: true
  use Witchcraft, override_kernel: false
  use Defr
  alias Algae.Reader

  defmodule User do
    use Defr

    defstruct [:id, :src]

    def get_src() do
      :db
    end

    defr get_by_id(user_id) do
      %__MODULE__{id: user_id, src: __MODULE__.get_src()}
    end
  end

  defmodule Accounts do
    use Defr

    defr get_user_by_id(user_id) do
      User.get_by_id(user_id)
    end
  end

  defmodule UserController do
    use Defr

    defr profile(user_id) do
      Accounts.get_user_by_id(user_id)
    end
  end

  test "User" do
    assert [{:get_by_id, 1}] == User.__defr__()

    assert %User{id: 1, src: :db} == User.get_by_id(1) |> Reader.run(%{})

    assert %User{id: 1, src: :mocked} ==
             User.get_by_id(1) |> Reader.run(mock(%{&User.get_src/0 => :mocked}))
  end

  test "Accounts" do
    assert [{:get_user_by_id, 1}] == Accounts.__defr__()

    assert %User{id: 1, src: :db} == Accounts.get_user_by_id(1) |> Reader.run(%{})

    assert %User{id: 1, src: :mocked} ==
             Accounts.get_user_by_id(1) |> Reader.run(mock(%{&User.get_src/0 => :mocked}))
  end

  test "UserController" do
    assert [{:profile, 1}] == UserController.__defr__()

    assert %User{id: 1, src: :db} == UserController.profile(1) |> Reader.run(%{})

    assert %User{id: 1, src: :mocked} ==
             UserController.profile(1) |> Reader.run(mock(%{&User.get_src/0 => :mocked}))
  end
end
