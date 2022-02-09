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

  def run(%Reather{reather: fun}, arg \\ %{}) do
    fun.(arg)
    # |> case do
    #   %Left{} = left ->
    #     left

    #   %Right{} = right ->
    #     right

    #   non_either ->
    #     raise RuntimeError,
    #           "Reather should return %Left{} or %Right{}, not #{inspect(non_either)}."
    # end
  end

  # defmacro run(reather, arg \\ Macro.escape(%{})) do
  #   quote do
  #     %Reather{reather: fun} = unquote(reather)

  #     fun.(unquote(arg)) |> Reather.Internal.confirm_either()
  #   end
  # end

  # defmodule Internal do
  #   def confirm_either(%Left{} = v), do: v
  #   def confirm_either(%Right{} = v), do: v

  #   def confirm_either(non_either) do
  #     raise RuntimeError, "Reather should return %Left{} or %Right{}, not #{inspect(non_either)}."
  #   end
  # end

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
