defmodule Defr.Inject do
  @moduledoc false

  defmacro __before_compile__(_env) do
    quote do
      def __defr_funs__ do
        @defr_funs
      end
    end
  end

  def convert_do_block({:__block__, ctx, exprs}) do
    build_do_block(ctx, exprs |> Enum.take(Enum.count(exprs) - 1), exprs |> List.last())
  end

  def convert_do_block({_, ctx, _} = expr) do
    build_do_block(ctx, [], expr)
  end

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

  def get_fa({:when, _, [name_args, _when_cond]}) do
    get_fa(name_args)
  end

  def get_fa({name, _, args}) when is_list(args) do
    {name, args |> Enum.count()}
  end

  def get_fa({name, _, _}) do
    {name, 0}
  end
end
