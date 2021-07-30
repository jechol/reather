defmodule Defre.NestedCallTest do
  use ExUnit.Case, async: true
  use Witchcraft, override_kernel: false
  alias Algae.Either.{Left, Right}
  alias Algae.Reader

  defmodule User do
    defstruct [:id, :src]

    def get_by_id(user_id) do
      %__MODULE__{id: user_id, src: :db}
    end
  end

  defmodule Accounts do
    def get_user_by_id(user_id) do
      User.get_by_id(user_id)
    end
  end

  defmodule UserController do
    def profile(user_id) do
      %User{id: id, src: src} = Accounts.get_user_by_id(user_id)
      "id: #{id}, src: #{src}"
    end
  end

  test "reader is available in nested call" do
    assert "id: 1, src: db" == UserController.profile(1)
  end
end
