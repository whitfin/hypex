defmodule Hypex.Register.List do
  @moduledoc """
  A `Hypex.Register` implementation using a `List`.

  This implementation offers good performance for smaller widths, for both
  reading and writing. However, writes scale poorly the larger the width of
  the `Hypex`.

  For smaller widths or in case of less frequent writes, this is likely a
  good candidate to consider. It's also easier to debug in tests due to
  being much more inspectable.
  """
  @behaviour Hypex.Register

  # define the register typespec
  @type t() :: list()

  @doc """
  Initialize an empty array register of a given width.
  """
  @spec init(width :: number()) :: t()
  def init(width),
    do: List.duplicate(0, :erlang.bsl(1, width))

  @doc """
  Retrieve a specific bit from a register.
  """
  @spec get(t(), index :: number(), width :: number()) :: result :: number()
  def get(register, index, _width),
    do: Enum.at(register, index)

  @doc """
  Set a specific bit in a register.
  """
  @spec put(t(), index :: number(), width :: number(), value :: number()) :: t()
  def put(register, index, _width, value),
    do: List.replace_at(register, index, value)

  @doc """
  Merge together two registers of the same width and type.
  """
  def merge(left, right),
    do: Enum.zip_with(left, right, &max/2)

  @doc """
  Run a reduction over the inner bits of a register.
  """
  def reduce(register, _width, acc, fun),
    do: Enum.reduce(register, acc, fun)
end
