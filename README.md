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
assert %Right{right: 15} ==
          (reather do
            a <- Right.new(1)
            b <- Reather.new(fn _ -> Right.new(2) end)
            c <- return 3
            d <- return %Right{right: 4}
            e <- Reather.ask()
            let sum = a + b + c + d + e

            sum
          end)
          |> Reather.run(5)
```

```elixir
reather sum(aa, bb, cc) do
  a <- aa
  b <- bb
  c <- cc
  d <- Reather.ask()

  a + b + c + d
end

test "function as reather" do
  assert %Right{right: 10} ==
            sum(1, Right.new(2), Reather.new(fn _ -> Right.new(3) end)) |> Reather.run(4)
end
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details
