defmodule Hypex.Bitstring do
  @moduledoc """
  This module provides a Hypex register implementation using a Bitstring under
  the hood.

  Using this implementation provides several guarantees about memory, in that the
  memory cost stays constant and falls well below that of other registers.

  Unfortunately this efficiency comes at the cost of some throughput, although
  this module should be easily sufficient for all but the most write-intensive
  use cases.
  """

  # define behaviour
  @behaviour Hypex.Register

  @doc """
  Creates a new bitstring with a size of `(2 ^ width) * width` with all bits initialized to 0.
  """
  @spec init(number) :: bitstring
  def init(width) do
    m = :erlang.bsl(1, width) * width
    << 0 :: size(m) >>
  end

  @doc """
  Takes a list of bits and converts them to a bitstring.

  We can just delegate to the native Erlang implementation as it provides the
  functionality we need built in.
  """
  @spec from_list([ bit :: number ]) :: bitstring
  defdelegate from_list(bit_list), to: :erlang, as: :list_to_bitstring

  @doc """
  Takes a bitstring and converts it to a list of bits.

  We can just delegate to the native Erlang implementation as it provides the
  functionality we need built in.
  """
  @spec to_list(bitstring) :: [ bit :: number ]
  defdelegate to_list(registers), to: :erlang, as: :bitstring_to_list

  @doc """
  Returns a bit from the list of registers.
  """
  @spec get_value(bitstring, idx :: number, width :: number) :: result :: number
  def get_value(registers, idx, width) do
    head_length = idx * width
    << _head :: bitstring-size(head_length), value :: size(width), _tail :: bitstring >> = registers
    value
  end

  @doc """
  Sets a bit inside the list of registers.
  """
  @spec set_value(bitstring, idx :: number, width :: number, value :: number) :: bitstring
  def set_value(registers, idx, width, value) do
    head_length = idx * width
    << head :: bitstring-size(head_length), _former :: size(width), tail :: bitstring >> = registers
    << head :: bitstring, value :: size(width), tail :: bitstring >>
  end

  @doc """
  Converts a list of registers into a provided accumulator.

  Internally we pass everything to the binary reduction function in the utils
  module, as there's already a native implementation for accumulation.
  """
  @spec reduce(bitstring, width :: number, accumulator :: any, (number, any -> any)) :: accumulator :: any
  defdelegate reduce(registers, width, acc, fun), to: Hypex.Util, as: :binary_reduce

  @doc false
  @spec merge(bitstring, bitstring) :: bitstring
  def merge(registers1, registers2) do
    merge2(registers1, registers2) |> from_list()
  end

  defp merge2(<<value1, registers1::bitstring>>, <<value2, registers2::bitstring>>) do
    [max(value1, value2) | merge2(registers1, registers2)]
  end

  defp merge2(<<>>, <<>>) do
    []
  end
end
