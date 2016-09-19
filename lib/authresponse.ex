defmodule AuthResponse do
  @derive [Poison.Encoder]
  defstruct [:url]
end
