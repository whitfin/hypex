defmodule ListRegister do
  @behaviour Hypex.Register

  # initialize
  def init(width),
  do: Enum.reduce(1..:erlang.bsl(1, width), [], fn(_, l) -> [ 0 | l ] end)

  # no-op
  def from_list(bits), do: bits

  # no-op
  def to_list(registers), do: registers

  # value retrieval
  def get_value(registers, idx, _width),
  do: Enum.at(registers, idx)

  # value modification
  def set_value(registers, idx, _width, value),
  do: List.replace_at(registers, idx, value)

  # reduction
  def reduce(registers, _width, acc, fun),
  do: Enum.reduce(registers, acc, fun)

end
