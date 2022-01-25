defmodule Reather do
  defmacro __using__([]) do
    quote do
      use Reather.Macros

      alias Witchcraft.{Functor, Applicative, Chain, Monad}
    end
  end

  use Witchcraft
  alias __MODULE__
  alias Algae.Either.{Left, Right}
  import Algae

  defdata(fun())

  def new(fun), do: %Reather{reather: fun}

  def ask(), do: Reather.new(fn env -> Right.new(env) end)

  def run(%Reather{reather: fun}, arg \\ %{}),
    do: fun.(arg) |> handle_either(&Quark.id/1, &Quark.id/1, "Reather.run should return")

  def handle_either(either, left_fun, right_fun, prefix) do
    case either do
      %Left{} = left ->
        left_fun.(left)

      %Right{} = right ->
        right_fun.(right)

      non_either ->
        raise RuntimeError,
              "#{prefix} %Left{} or %Right{}, not #{inspect(non_either)}."
    end
  end

  # Macro shortcuts

  defmacro inject(call) do
    quote do
      Reather.Macros.inject(unquote(call))
    end
  end

  defmacro mock(mocks) do
    quote do
      Reather.Macros.mock(unquote(mocks))
    end
  end

  defmacro reatherfy(fun) do
    quote do
      Reather.Macros.reatherfy(unquote(fun))
    end
  end
end

alias Algae.Either.{Left, Right}
import TypeClass
use Witchcraft

definst Witchcraft.Functor, for: Reather do
  @force_type_instance true
  def map(%Reather{reather: inner_fun}, fun) do
    Reather.new(fn env ->
      inner_fun.(env)
      |> Reather.handle_either(
        &Quark.id/1,
        fn %Right{right: value} -> fun.(value) |> Right.new() end,
        "Reather function return"
      )
    end)
  end
end

definst Witchcraft.Applicative, for: Reather do
  @force_type_instance true
  def of(%Reather{}, either) do
    reather = fn either -> Reather.new(fn _env -> either end) end
    Reather.handle_either(either, reather, reather, "`return` argument should be")
  end
end

definst Witchcraft.Chain, for: Reather do
  @force_type_instance true
  alias Reather

  def chain(%Reather{} = reather, link) do
    Reather.new(fn env ->
      reather
      |> Reather.run(env)
      |> Reather.handle_either(
        &Quark.id/1,
        fn %Right{right: value} ->
          link.(value) |> Reather.run(env)
        end,
        "Unreachable code"
      )
    end)
  end
end

definst Witchcraft.Monad, for: Reather do
  @force_type_instance true
end
