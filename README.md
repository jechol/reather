[![mix test](https://github.com/trevorite/defr/workflows/mix%20test/badge.svg)](https://github.com/trevorite/defr/actions)
[![Hex version badge](https://img.shields.io/hexpm/v/defr.svg)](https://hex.pm/packages/defr)
[![License badge](https://img.shields.io/hexpm/l/defr.svg)](https://github.com/trevorite/defr/blob/master/LICENSE.md)

`defr` is `def` for Witchcraft's Reader monads.

## Installation

The package can be installed by adding `defr` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:defr, "~> 0.3"}]
end
```

To format `defr` like `def`, add following to your `.formatter.exs`

```elixir
locals_without_parens: [defr: 2]
```

## `defr` transformation

```elixir
defmodule Target do
  use Defr

  import Enum, only: [at: 2]

  defr top(list) do
    list |> List.flatten() |> inject() |> middle() |> run()
  end

  defr middle(list) do
    list |> bottom() |> inject() |> run()
  end

  defrp bottom(list) do
    %{pos: pos} <- ask()
    list |> at(pos) |> inject()
  end
end
```

becomes (simplified for clarity)

```elixir
defmodule Target do
  def top(list)  do
    monad(%Algae.Reader{}) do
      env <- Algae.Reader.ask()
      return(
        list
        |> Map.get(env, &List.flatten/1, &List.flatten/1).()
        |> middle()
        |> Reader.run(env)
      )
    end
  end

  def middle(list) do
    monad %Algae.Reader{}  do
      env <- Algae.Reader.ask()
      return(
        list
        |> Map.get(env, &Target.bottom/1, &Target.bottom/1).()
        |> Reader.run(env)
      )
    end
  end

  defp bottom(list) do
    monad %Algae.Reader{} do
      env <- Algae.Reader.ask()
      %{pos: pos} <- Algae.Reader.ask()
      return(
        list
        |> Map.get(env, &Enum.at/2, &Enum.at/2).(pos)
      )
    end
  end
end
```

## Test

```elixir
test "defr" do
  assert 1 == Target.top([[0], 1]) |> Reader.run(%{pos: 1})

  assert 20 ==
            Target.top([[0], 1]) |> Reader.run(mock(%{&List.flatten/1 => [10, 20, 30], pos: 1}))

  assert :imported_func ==
            Target.top([[0], 1]) |> Reader.run(mock(%{&Enum.at/2 => :imported_func, pos: 1}))

  assert :private_func ==
            Target.top([[0], 1])
            |> Reader.run(mock(%{&Target.bottom/1 => :private_func}))
end
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details
