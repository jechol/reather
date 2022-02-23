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

  defstruct reather: &Quark.id/1

  def new(fun), do: %Reather{reather: fun}
  def of(value), do: Witchcraft.Applicative.of(%Reather{}, value)

  def ask(), do: Reather.new(fn env -> Right.new(env) end)

  def inspect(%Reather{} = r, opts \\ []) do
    Reather.new(fn env ->
      r |> Reather.run(env) |> IO.inspect(opts)
    end)
  end

  def run(%Reather{reather: fun}, arg \\ %{}) do
    fun.(arg)
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
      |> case do
        %Left{} = left ->
          left

        %Right{right: value} ->
          fun.(value) |> Right.new()

        non_either ->
          raise RuntimeError,
                "Reather should return %Left{} or %Right{}, not #{inspect(non_either)}."
      end
    end)
  end
end

definst Witchcraft.Applicative, for: Reather do
  @force_type_instance true
  def of(%Reather{}, either) do
    either
    |> case do
      %Left{} = left ->
        Reather.new(fn _env -> left end)

      %Right{} = right ->
        Reather.new(fn _env -> right end)

      value ->
        # Here we accept value and wrap inside %Right{} for smooth migration.
        Reather.new(fn _env -> value |> Right.new() end)
    end
  end
end

definst Witchcraft.Chain, for: Reather do
  @force_type_instance true
  alias Reather

  def chain(%Reather{reather: fun} = reather, link) do
    require Reather

    Reather.new(fn env ->
      reather
      |> Reather.run(env)
      |> case do
        %Left{} = left ->
          left

        %Right{right: value} ->
          link.(value) |> Reather.run(env)
      end
    end)
  end
end

definst Witchcraft.Monad, for: Reather do
  @force_type_instance true
end
