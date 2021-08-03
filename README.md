[![mix test](https://github.com/trevorite/defr/workflows/mix%20test/badge.svg)](https://github.com/trevorite/defr/actions)
[![Hex version badge](https://img.shields.io/hexpm/v/defr.svg)](https://hex.pm/packages/defr)
[![License badge](https://img.shields.io/hexpm/l/defr.svg)](https://github.com/trevorite/defr/blob/master/LICENSE.md)

`defr` is `def` for Witchcraft's Reader monads.

## Installation

The package can be installed by adding `defr` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:defr, "~> 0.1"}]
end
```

To format `defr` like `def`, add following to your `.formatter.exs`

```elixir
locals_without_parens: [defr: 2]
```

## `defr` transformation

```elixir
defmodule Password do
  def validate(pw, pw_hash) do
    :crypto.hash(:sha3_256, pw) == pw_hash
  end
end

defmodule User do
  use Defr

  defstruct [:id, :pw_hash]

  defr get_by_id(user_id) do
    Repo.get(__MODULE__, user_id)
  end
end

defmodule Accounts do
  use Defr

  defr sign_in(user_id, pw) do
    user = User.get_by_id(user_id)
    Password.validate(pw, user.pw_hash)
  end
end
```

becomes (simplified for clarity)

```elixir
defmodule Password do
  def validate(pw, pw_hash) do
    :crypto.hash(:sha3_256, pw) == pw_hash
  end
end

defmodule User do
  use Defr

  defstruct [:id, :pw_hash]

  def get_by_id(user_id) do
    monad %Reader{} do
      deps <- ask()
      return (
        Map.get(deps, &Repo.get/2, &Repo.get/2).(__MODULE__, user_id)
      )
    end
  end
end

defmodule Accounts do
  use Defr

  def sign_in(user_id, pw) do
    monad %Reader{} do
      deps <- ask()
      return (
        (
          user = Map.get(deps, &User.get_by_id/1, &User.get_by_id/1).(user_id) |> Reader.run(deps)
          Password.validate(pw, user.pw_hash)
        )
      )
    end
  end
end
```

# Test

## Injection normal function

```elixir
test "Injecting normal function" do
  assert true ==
            Accounts.sign_in(100, "Ju8AufbPr*")
            |> Reader.run(%{
              &Repo.get/2 => fn _schema, _user_id ->
                %User{id: 100, pw_hash: :crypto.hash(:sha3_256, "Ju8AufbPr*")}
              end
            })

  # simpilfied with `mock`
  assert true ==
            Accounts.sign_in(100, "hello")
            |> Reader.run(
              mock(%{&Repo.get/2 => %User{id: 100, pw_hash: :crypto.hash(:sha3_256, "hello")}})
            )
end
```

## Injection reader function

```elixir
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
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details
