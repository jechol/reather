defmodule Reather do
  defmacro __using__([]) do
    quote do
      use Reather.Macros

      import Reather, only: [ask: 0, ask: 1]
    end
  end

  use Witchcraft
  alias __MODULE__
  alias Algae.Either.{Left, Right}
  import Algae

  defdata(fun())

  def new(fun), do: %Reather{reather: fun}
  def left(error), do: new(fn _ -> Left.new(error) end)
  def right(value), do: new(fn _ -> Right.new(value) end)

  def run(%Reather{reather: fun}, arg), do: fun.(arg) |> ensure_either()

  def ask(), do: Reather.new(fn env -> Right.new(env) end)

  def ask(fun) do
    monad %Reather{} do
      env <- ask()
      return(Right.new(fun.(env)))
    end
  end

  def ensure_either(%Left{} = v), do: v
  def ensure_either(%Right{} = v), do: v
end

alias Algae.Either.{Left, Right}
import TypeClass
use Witchcraft

definst Witchcraft.Functor, for: Reather do
  @force_type_instance true
  def map(%Reather{reather: inner}, fun) do
    Reather.new(fn env ->
      case inner.(env) do
        %Left{} = left -> left
        %Right{right: value} -> Right.new(fun.(value))
      end
    end)
  end
end

definst Witchcraft.Applicative, for: Reather do
  @force_type_instance true
  def of(_, %Left{} = value), do: Reather.new(fn _env -> value end)
  def of(_, %Right{} = value), do: Reather.new(fn _env -> value end)
end

definst Witchcraft.Chain, for: Reather do
  @force_type_instance true
  alias Reather

  def chain(reather, link) do
    Reather.new(fn env ->
      case reather |> Reather.run(env) do
        %Left{} = left -> left
        %Right{right: value} -> link.(value) |> Reather.run(env)
      end
    end)
  end
end

definst Witchcraft.Monad, for: Reather do
  @force_type_instance true
end
