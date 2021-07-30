![](https://github.com/trevorite/defr/blob/master/brand/logo.png?raw=true)

[![mix test](https://github.com/trevorite/defr/workflows/mix%20test/badge.svg)](https://github.com/trevorite/defr/actions)
[![Hex version badge](https://img.shields.io/hexpm/v/defr.svg)](https://hex.pm/packages/defr)
[![License badge](https://img.shields.io/hexpm/l/defr.svg)](https://github.com/trevorite/defr/blob/master/LICENSE.md)

`defr` is `def` for Witchcraft's Reader, Either monads.

## Why?

Let's say we want to test following function.

```elixir
def send_welcome_email(user_id) do
  %{email: email} = Repo.get(User, user_id)

  welcome_email(to: email)
  |> Mailer.send()
end
```

Here's one possible solution to replace `Repo.get/2` and `Mailer.send/1` with mocks:

```elixir
def send_welcome_email(user_id, repo \\ Repo, mailer \\ Mailer) do
  %{email: email} = repo.get(User, user_id)

  welcome_email(to: email)
  |> mailer.send()
end
```

First, I believe that this approach is too obtrusive as it requires modifying the function body to make it testable. Second, with `Mailer` replaced with `mailer`, the compiler no longer check the existence of `Mailer.send/1`.

`defr` does not require you to modify function arguments or body. It allows injecting different mocks to each function. It also does not limit using `:async` option as mocks are contained in each test function.

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

## Documentation

API documentation is available at [https://hexdocs.pm/defr](https://hexdocs.pm/defr)

## Usage

### use Defr

`defr` transforms body to be injectable with Witchcraft's Algae.Reader monad.

```elixir
use Defr

def send_welcome_email(user_id) do
  %{email: email} = Repo.get(User, user_id)

  welcome_email(to: email)
  |> Mailer.send()
end
```

is expanded into

```elixir
def send_welcome_email(user_id, deps \\ %{}) do
  %{email: email} =
    Map.get(deps, &Repo.get/2,
      :erlang.make_fun(Map.get(deps, Repo, Repo), :get, 2)
    ).(User, user_id)

  welcome_email(to: email)
  |> Map.get(deps, &Mailer.send/1,
       :erlang.make_fun(Map.get(deps, Mailer, Mailer), :send, 1)
     ).()
end
```

Note that local function calls like `welcome_email(to: email)` are not expanded unless it is prepended with `__MODULE__`.

Now, you can inject mock functions and modules in tests.

```elixir
test "send_welcome_email" do
  Accounts.send_welcome_email(100, %{
    Repo => MockRepo,
    &Mailer.send/1 => fn %Email{to: "user100@gmail.com", subject: "Welcome"} ->
      Process.send(self(), :email_sent)
    end
  })

  assert_receive :email_sent
end
```

Function calls raise if the `deps` includes redundant functions or modules.
You can disable this by adding `strict: false` option.

```elixir
test "send_welcome_email with strict: false" do
  Accounts.send_welcome_email(100, %{
    &Repo.get/2 => fn User, 100 -> %User{email: "user100@gmail.com"} end,
    &Repo.all/1 => fn _ -> [%User{email: "user100@gmail.com"}] end, # Unused
    strict: false
  })
end
```

### mock

If you don't need pattern matching in mock function, `mock/1` can be used to reduce boilerplates.

```elixir
import Defr

test "send_welcome_email with mock/1" do
  Accounts.send_welcome_email(
    100,
    mock(%{
      Repo => MockRepo,
      &Mailer.send/1 => Process.send(self(), :email_sent)
    })
  )

  assert_receive :email_sent
end
```

Note that `Process.send(self(), :email_sent)` is surrounded by `fn _ -> end` when expanded.

### import Defr

`import Defr` instead of `use Defr` if you want to manually select functions to inject.

```elixir
import Defr

defr send_welcome_email(user_id) do
  %{email: email} = Repo.get(User, user_id)

  welcome_email(to: email)
  |> Mailer.send()
end
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details
