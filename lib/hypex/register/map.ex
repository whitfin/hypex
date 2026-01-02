defmodule Hypex.Register.Map do
  @moduledoc """
  A `Hypex.Register` implementation using a `Map`.

  Maps offer sparse register storage, leading to efficient memory usage. The
  quick access time leaves them well suited to both read and write use cases,
  but they don't scale as well as `Hypex.Register.Array` to higher cardinality.

  Recommended for lower cardinality use cases, or when memory is more important.
  """
  @behaviour Hypex.Register

  # define the register typespec
  @type t() :: map()

  @doc """
  Initialize an empty array register of a given width.
  """
  @spec init(width :: number()) :: t()
  def init(_width),
    do: %{}

  @doc """
  Retrieve a specific bit from a register.
  """
  @spec get(t(), index :: number(), width :: number()) :: result :: number()
  def get(register, index, _width),
    do: Map.get(register, index, 0)

  @doc """
  Set a specific bit in a register.
  """
  @spec put(t(), index :: number(), width :: number(), value :: number()) :: t()
  def put(register, index, _width, value),
    do: Map.put(register, index, value)

  @doc """
  Merge together two registers of the same width and type.
  """
  @spec merge(t(), t()) :: t()
  def merge(left, right),
    do: Map.merge(left, right, fn _key, v1, v2 -> max(v1, v2) end)

  @doc """
  Run a reduction over the inner bits of a register.
  """
  @spec reduce(t(), width :: number(), accumulator :: any(), (number, any -> any)) ::
          accumulator :: any()
  def reduce(register, width, acc, fun) do
    size = :erlang.bsl(1, width)
    zeroes = size - map_size(register)

    acc =
      Enum.reduce(register, acc, fn {_key, value}, acc ->
        fun.(value, acc)
      end)

    Enum.reduce(1..zeroes//1, acc, fn _, acc -> fun.(0, acc) end)
  end
end
