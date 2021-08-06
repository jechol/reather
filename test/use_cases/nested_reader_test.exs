defmodule Defr.NestedReaderTest do
  use ExUnit.Case, async: true
  use Defr
  alias Algae.Reader

  defmodule Repo do
    def get(_schema, _id) do
      raise "Should'n be called!"
    end
  end

  defmodule Password do
    def validate(pw, pw_hash) do
      :crypto.hash(:sha3_256, pw) == pw_hash
    end
  end

  defmodule User do
    use Defr

    defstruct [:id, :pw_hash]

    defr get_by_id(user_id) do
      let user_id = noop(user_id) |> inject() |> run()
      Repo.get(__MODULE__, user_id) |> inject()
    end

    defr noop(v) do
      v
    end
  end

  defmodule Accounts do
    use Defr

    defr sign_in(user_id, pw) do
      let user = User.get_by_id(user_id) |> inject() |> run()
      Password.validate(pw, user.pw_hash)
    end
  end

  test "Injecting normal function" do
    assert true ==
             Accounts.sign_in(100, "Ju8AufbPr*")
             |> Reader.run(%{
               &Repo.get/2 => fn _schema, _user_id ->
                 %User{id: 100, pw_hash: :crypto.hash(:sha3_256, "Ju8AufbPr*")}
               end
             })

    assert true ==
             Accounts.sign_in(100, "hello")
             |> Reader.run(
               mock(%{&Repo.get/2 => %User{id: 100, pw_hash: :crypto.hash(:sha3_256, "hello")}})
             )
  end

  test "Injecting reader function" do
    assert true ==
             Accounts.sign_in(100, "Ju8AufbPr*")
             |> Reader.run(%{
               &User.get_by_id/1 => fn _user_id ->
                 Reader.new(fn _env ->
                   %User{id: 100, pw_hash: :crypto.hash(:sha3_256, "Ju8AufbPr*")}
                 end)
               end
             })

    # simpilfied with `mock`
    assert true ==
             Accounts.sign_in(100, "hello")
             |> Reader.run(
               mock(%{
                 &User.get_by_id/1 => %User{id: 100, pw_hash: :crypto.hash(:sha3_256, "hello")}
               })
             )
  end
end
