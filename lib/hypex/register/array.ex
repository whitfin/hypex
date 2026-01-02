defmodule Hypex.Register.Array do
  @moduledoc """
  A `Hypex.Register` implementation using an Erlang `:array`.

  Arrays offer the best average throughput and scale well to various widths and
  cardinalities. For this reason this register is the default chosen when non
  is explicitly requested.

  This register will scale to many use cases, and should be a solid choice for
  many users as a balance of memory, throughput and flexibility.

  Recommended for general usage or when traffic patterns are less defined.
  """
  @behaviour Hypex.Register

  # define the register typespec
  @type t() :: :array.array(number())

  @doc """
  Initialize an empty array register of a given width.
  """
  @spec init(width :: number()) :: t()
  def init(width) do
    1
    |> :erlang.bsl(width)
    |> :array.new({:default, 0})
  end

  @doc """
  Retrieve a specific bit from a register.
  """
  @spec get(t(), index :: number(), width :: number()) :: result :: number()
  def get(register, index, _width),
    do: :array.get(index, register)

  @doc """
  Set a specific bit in a register.
  """
  @spec put(t(), index :: number(), width :: number(), value :: number()) :: t()
  def put(register, index, _width, value),
    do: :array.set(index, value, register)

  @doc """
  Merge together two registers of the same width and type.
  """
  @spec merge(left :: t(), right :: t()) :: register :: t()
  def merge(left, right) do
    :array.map(
      fn idx, value ->
        max(value, :array.get(idx, right))
      end,
      left
    )
  end

  @doc """
  Run a reduction over the inner bits of a register.
  """
  @spec reduce(t(), width :: number(), accumulator :: any(), (number, any -> any)) ::
          accumulator :: any()
  def reduce(register, _width, acc, fun),
    do:
      :array.foldl(
        fn _, int, acc ->
          fun.(int, acc)
        end,
        acc,
        register
      )
end
