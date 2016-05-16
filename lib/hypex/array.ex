defmodule Hypex.Array do
  @moduledoc """
  This module provides a Hypex register implementation using an Erlang Array under
  the hood.

  Using an Array switches out the memory efficiency of the Bitstring implementation
  for performance, operating at 10x the throughput of Bitstring on updates.

  Even though this implementation uses higher amounts of memory, it's still pretty
  low-cost and as such is the default register module for Hypex. Typically only
  those working in memory-constrained environments should consider the Bitstring
  register.
  """

  # define behaviour
  @behaviour Hypex.Register

  # define the Array typespec
  @type array :: :array.array(number)

  @doc """
  Creates a new Array with a size of `2 ^ width` with all elements initialized to 0.
  """
  @spec init(width :: number) :: array
  def init(width) do
    1
    |> :erlang.bsl(width)
    |> :array.new({ :default, 0 })
  end

  @doc """
  Takes a list of bits and converts them to an Array.

  The Array has it's size fixed before being returned just for some extra safety.
  """
  @spec from_list([ bit :: number ]) :: array
  def from_list(bits) do
    bits
    |> :array.from_list(0)
    |> :array.fix
  end

  @doc """
  Converts an Array register implementation to a list of bits.

  We can just delegate to the internal Array implementation as it provides the
  functionality we need built in.
  """
  @spec to_list(array) :: [ bit :: number ]
  defdelegate to_list(registers), to: :array, as: :to_list

  @doc """
  Returns a bit from the list of registers.
  """
  @spec get_value(array, idx :: number, width :: number) :: result :: number
  def get_value(registers, idx, _width) do
    :array.get(idx, registers)
  end

  @doc """
  Sets a bit inside the list of registers.
  """
  @spec set_value(array, idx :: number, width :: number, value :: number) :: array
  def set_value(registers, idx, _width, value) do
    :array.set(idx, value, registers)
  end

  @doc """
  Converts a list of registers into a provided accumulator.

  Internally we pass everything to `:array.foldl/3`, as there's already a native
  implementation for accumulation.
  """
  @spec reduce(array, width :: number, accumulator :: any, (number, any -> any)) :: accumulator :: any
  def reduce(registers, _width, acc, fun) do
    :array.foldl(fn(_, int, acc) ->
      fun.(int, acc)
    end, acc, registers)
  end

end
