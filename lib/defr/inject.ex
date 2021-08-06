defmodule Defr.Inject do
  @moduledoc false
  def convert_do_block({:__block__, ctx, exprs}) do
    build_do_block(ctx, exprs |> Enum.take(Enum.count(exprs) - 1), exprs |> List.last())
  end

  def convert_do_block({_, ctx, _} = expr) do
    build_do_block(ctx, [], expr)
  end

  # Private

  defp build_do_block(ctx, except_last, last) do
    monad_body =
      [
        quote do
          var!(deps) <- Algae.Reader.ask()
        end,
        quote do
          let _ = var!(deps)
        end
        | except_last
      ] ++
        [
          quote do
            return(unquote(last))
          end
        ]

    quote do
      use Witchcraft.Monad

      monad %Algae.Reader{} do
        unquote({:__block__, ctx, monad_body})
      end
    end
  end
end
