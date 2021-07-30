defmodule Defre.NestedCallTest do
  use ExUnit.Case, async: true
  use Witchcraft, override_kernel: false
  import Defre
  alias Algae.Either.Right
  alias Algae.Reader

  defmodule User do
    defstruct [:id, :src]

    def get_by_id(user_id) do
      monad %Reader{} do
        env <- Reader.ask()
        return(%__MODULE__{id: user_id, src: Map.get(env, :src, :db)} |> Right.new())
      end
    end
  end

  defmodule Accounts do
    def get_user_by_id(user_id) do
      User.get_by_id(user_id)
    end
  end

  defmodule UserController do
    def profile(user_id) do
      monad %Reader{} do
        env <- Reader.ask()

        return(
          monad %Right{} do
            %User{id: id, src: src} <- Accounts.get_user_by_id(user_id) |> Reader.run(env)
            "id: #{id}, src: #{src}" |> Right.new()
          end
        )
      end
    end

    defre profile_re(user_id) do
      %User{id: id, src: src} <- Accounts.get_user_by_id(user_id)
      "id: #{id}, src: #{src}" |> Right.new()
    end
  end

  test "reader is available in nested call" do
    assert %Right{right: "id: 1, src: db"} == UserController.profile(1) |> Reader.run(%{})
  end
end
