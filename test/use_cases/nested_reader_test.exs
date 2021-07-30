defmodule Defr.NestedCallTest do
  use ExUnit.Case, async: true
  use Witchcraft, override_kernel: false
  use Defr
  alias Algae.Reader
  alias Algae.Either.Right

  defmodule User do
    use Defr

    defstruct [:id, :name]

    defr get_by_id(user_id) do
      Repo.get(__MODULE__, user_id) |> Right.new()
    end
  end

  defmodule Accounts do
    use Defr

    defr get_user_by_id(user_id) do
      monad %Right{} do
        user <- User.get_by_id(user_id)
        user |> Right.new()
      end
    end
  end

  defmodule UserController do
    use Defr

    defr profile(user_id_str) do
      user_id = String.to_integer(user_id_str)
      Accounts.get_user_by_id(user_id)
    end
  end

  test "UserController" do
    assert [{:profile, 1}] == UserController.__reader_funs__()

    assert %Right{right: %User{id: 1, name: "josevalim"}} ==
             UserController.profile("1")
             |> Reader.run(%{&Repo.get/2 => fn _, _ -> %User{id: 1, name: "josevalim"} end})
  end
end
