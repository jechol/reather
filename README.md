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

## `reather` transformation

```elixir
defmodule Target do
  use Reather

  import Enum, only: [at: 2]

  reather top(list) do
    list |> List.flatten() |> inject() |> middle()
  end

  reather middle(list) do
    list |> bottom() |> inject()
  end

  reatherp bottom(list) do
    %{pos: pos} <- Reather.ask()
    return at(list, pos) |> inject() |> Right.new()
  end
end
```

becomes (simplified for clarity)

```elixir
defmodule Target do
  def top(list)  do
    monad %Reather{}  do
      env <- Reather.ask()

      list
      |> Map.get(env, &List.flatten/1, &List.flatten/1).()
      |> middle()
    end
  end

  def middle(list) do
    monad %Reather{}  do
      env <- Reather.ask()

      list
      |> Map.get(env, &Target.bottom/1, &Target.bottom/1).()
    end
  end

  defp bottom(list) do
    monad %Reather{} do
      env <- Reather.ask()
      %{pos: pos} <- Reather.ask()

      return(
        list
        |> Map.get(env, &Enum.at/2, &Enum.at/2).(pos)
        |> Right.new()
      )
    end
  end
end
```

## Test

```elixir
test "inject" do
  assert %Right{right: 1} == Target.top([[0], 1]) |> Reather.run(%{pos: 1})

  assert %Right{right: 20} ==
            Target.top([[0], 1]) |> Reather.run(mock(%{&List.flatten/1 => [10, 20, 30], pos: 1}))

  assert %Right{right: :imported_func} ==
            Target.top([[0], 1]) |> Reather.run(mock(%{&Enum.at/2 => :imported_func, pos: 1}))

  assert %Right{right: :private_func} ==
            Target.top([[0], 1])
            |> Reather.run(mock(%{&Target.bottom/1 => Right.new(:private_func)}))
end
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details
