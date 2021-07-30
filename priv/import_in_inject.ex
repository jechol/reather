defmodule ImportInInject do
  use Defre

  defre str_to_atom(str) do
    import Calc
    to_int(str)
  end
end
