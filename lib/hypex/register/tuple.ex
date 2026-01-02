defmodule Hypex.Register.Tuple do
  @moduledoc """
  A `Hypex.Register` implementation using a `Tuple`.

  Tuples offer quick access and are useful for read-heavy use cases. Due
  to creation of a new tuple on write, not recommended for frequent writes
  due to memory churn.

  Recommended for read-heavy use cases with widths generally up to 12.
  """
  @behaviour Hypex.Register

  # define the register typespec
  @type t() :: map()

  @doc """
  Initialize an empty array register of a given width.
  """
  @spec init(width :: number()) :: t()
  def init(width) do
    width
    |> Hypex.Register.List.init()
    |> List.to_tuple()
  end

  @doc """
  Retrieve a specific bit from a register.
  """
  @spec get(t(), index :: number(), width :: number()) :: result :: number()
  def get(register, index, _width),
    do: elem(register, index)

  @doc """
  Set a specific bit in a register.
  """
  @spec put(t(), index :: number(), width :: number(), value :: number()) :: t()
  def put(register, index, _width, value),
    do: put_elem(register, index, value)

  @doc """
  Merge together two registers of the same width and type.
  """
  @spec merge(t(), t()) :: t()
  def merge(left, right) do
    List.to_tuple(
      for idx <- 0..(tuple_size(left) - 1) do
        max(elem(left, idx), elem(right, idx))
      end
    )
  end

  @doc """
  Run a reduction over the inner bits of a register.
  """
  @spec reduce(t(), width :: number(), accumulator :: any(), (number, any -> any)) ::
          accumulator :: any()
  def reduce(register, _width, acc, fun),
    do: register |> Tuple.to_list() |> Enum.reduce(acc, fun)
end
