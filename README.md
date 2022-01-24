[![mix test](https://github.com/jechol/reather/workflows/mix%20test/badge.svg)](https://github.com/jechol/reather/actions)
[![Hex version badge](https://img.shields.io/hexpm/v/reather.svg)](https://hex.pm/packages/reather)
[![License badge](https://img.shields.io/hexpm/l/reather.svg)](https://github.com/jechol/reather/blob/master/LICENSE.md)

`reather` is `def` for Witchcraft's Reader + Either monads.

## Installation

The package can be installed by adding `reather` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:reather, "~> 0.1"}]
end
```

To format `reather` like `def`, add following to your `.formatter.exs`

```elixir
locals_without_parens: [reather: 2]
```

## `reather`, `left/right`, `ask`, `inject`, `mock`

```elixir
defmodule Target do
  use Reather

  defmodule Impure do
    reather read("invalid") do
      Reather.left(:enoent)
    end

    reather read("valid") do
      Reather.right(99)
    end
  end

  reather read_and_multiply(filename) do
    input <- Impure.read(filename) |> Reather.inject()

    multiply(input)
  end

  reatherp multiply(input) do
    %{number: number} <- Reather.ask()

    Reather.right(input * number)
  end
end
```

```elixir
use Reather

assert %Left{left: :enoent} = Target.read_and_multiply("invalid") |> Reather.run()
assert %Right{right: 990} = Target.read_and_multiply("valid") |> Reather.run(%{number: 10})

assert %Right{right: 880} =
          Target.read_and_multiply("valid")
          |> Reather.overlay(Reather.mock(%{&Target.Impure.read/1 => Reather.right(88)}))
          |> Reather.run(%{number: 10})
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details
