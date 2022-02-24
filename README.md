[![mix test](https://github.com/jechol/reather/workflows/mix%20test/badge.svg)](https://github.com/jechol/reather/actions)
[![Hex version badge](https://img.shields.io/hexpm/v/reather.svg)](https://hex.pm/packages/reather)
[![License badge](https://img.shields.io/hexpm/l/reather.svg)](https://github.com/jechol/reather/blob/main/LICENSE.md)

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

## Usage

#### `reather`, `ask`, `let`, `run`

```elixir
defmodule Example do
  use Reather

  reather next(number) do
    n <- number
    %{step: step} <- Reather.ask()

    let sum = n + step
    sum
  end

  test "next/1" do
    assert Right.new(15) == next(10) |> Reather.run(%{step: 5})
    assert Right.new(15) == next(Right.new(10)) |> Reather.run(%{step: 5})
    assert Right.new(15) == next(Reather.of(10)) |> Reather.run(%{step: 5})

    assert Left.new(:NaN) == next(Left.new(:NaN)) |> Reather.run(%{step: 5})
    assert Left.new(:NaN) == next(Reather.of(Left.new(:NaN))) |> Reather.run(%{step: 5})
  end
end
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details
