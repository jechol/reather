defmodule ImportInInject do
  use Defr

  defre str_to_atom(str) do
    import Calc
    to_int(str)
  end
end
