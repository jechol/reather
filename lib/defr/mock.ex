defmodule Defr.Mock do
  @moduledoc false
  alias Algae.Reader

  def decorate_with_fn({{:&, _, [{:/, _, [{{:., _, [m, f]}, _, []}, a]}]} = capture, v}) do
    const_fn = {:fn, [], [{:->, [], [Macro.generate_arguments(a, __MODULE__), v]}]}

    reader_fn =
      {:fn, [],
       [
         {:->, [],
          [
            Macro.generate_arguments(a, __MODULE__),
            quote do
              Reader.new(fn _deps -> unquote(v) end)
            end
          ]}
       ]}

    value =
      quote do
        Defr.Mock.wrap_if_reader(
          {unquote(m), unquote(f), unquote(a)},
          unquote(const_fn),
          unquote(reader_fn)
        )
      end

    {capture, value}
  end

  def wrap_if_reader({m, f, a}, const_fn, reader_fn) do
    if Defr.Runner.is_defr_fun?({m, f, a}) do
      reader_fn
    else
      const_fn
    end
  end
end
