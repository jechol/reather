defmodule Reather.Macros do
  alias Algae.Either.{Left, Right}

  defmacro __using__([]) do
    quote do
      use Witchcraft, override_kernel: false
      alias Algae.Either.{Left, Right}

      import Reather.Macros, only: [reather: 1, reather: 2, reatherp: 2]
    end
  end

  defmacro reather(head, do: body) do
    fa = get_fa(head)
    do_block = body |> convert_do_block()

    quote do
      def unquote(head) do
        unquote(do_block)
      end
    end
    |> trace()
  end

  defmacro reatherp(head, do: body) do
    fa = get_fa(head)
    do_block = body |> convert_do_block()

    quote do
      defp unquote(head) do
        unquote(do_block)
      end
    end
    |> trace()
  end

  # Private

  defp get_fa({:when, _, [name_args, _when_cond]}) do
    get_fa(name_args)
  end

  defp get_fa({name, _, args}) when is_list(args) do
    {name, args |> Enum.count()}
  end

  defp get_fa({name, _, _}) do
    {name, 0}
  end

  defp convert_do_block({:__block__, ctx, exprs}) do
    build_do_block(ctx, exprs)
  end

  defp convert_do_block(expr) do
    build_do_block([], [expr])
  end

  defp build_do_block(ctx, exprs) do
    monad_body = exprs

    quote do
      use Witchcraft, override_kernel: false

      %Reather{} =
        reather do
          unquote({:__block__, ctx, monad_body})
        end
    end
  end

  @trace Application.compile_env(:reather, :trace, false)
  defp trace(ast) do
    if @trace do
      ast |> Macro.to_string() |> IO.puts()
      ast
    else
      ast
    end
  end

  defmacro reather(do: input) do
    sample = quote do: %Reather{}
    returnized = Witchcraft.Monad.desugar_return(input, sample)
    do_notation(returnized)
  end

  def do_notation(input) do
    [head | tail] = input |> normalize() |> Enum.reverse()

    wrapped_head =
      quote do
        unquote(head) |> Reather.Macros.wrap_in_reather()
      end

    Witchcraft.Foldable.left_fold(tail, wrapped_head, fn
      continue, {:let, _, [{:=, _, [assign, value]}]} ->
        quote do: unquote(value) |> (fn unquote(assign) -> unquote(continue) end).()

      continue, {:<-, _, [assign, value]} ->
        quote do
          import Witchcraft.Chain, only: [>>>: 2]

          # Here we accept not only Reather, but also Either for smooth migration.
          unquote(value) |> Reather.Macros.wrap_in_reather() >>>
            fn unquote(assign) -> unquote(continue) end
        end

      continue, value ->
        quote do
          import Witchcraft.Chain, only: [>>>: 2]

          # Here we accept not only Reather, but also Either for smooth migration.
          unquote(value) |> Reather.Macros.wrap_in_reather() >>>
            fn _ -> unquote(continue) end
        end
    end)
  end

  @doc false
  def normalize({:__block__, _, inner}), do: inner
  def normalize(single) when is_list(single), do: [single]
  def normalize(plain), do: [plain]

  def wrap_in_reather(%Reather{} = r), do: r
  def wrap_in_reather(non_reather), do: Witchcraft.Applicative.of(%Reather{}, non_reather)
end
