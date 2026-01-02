defmodule Hypex.Register.Bitstring do
  @moduledoc """
  A `Hypex.Register` implementation using a bitstring.

  This register is useful for keeping memory usage down, while still offering good
  performance. You should consider this register when memory constraints are an
  important factor.

  Recommended for larger widths, or when memory efficiency is a major concern.
  """
  @behaviour Hypex.Register

  # define the register typespec
  @type t() :: bitstring()

  @doc """
  Initialize an empty array register of a given width.
  """
  @spec init(width :: number()) :: register :: t()
  def init(width) do
    m = :erlang.bsl(1, width) * width
    <<0::size(m)>>
  end

  @doc """
  Retrieve a specific bit from a register.
  """
  @spec get(t(), index :: number(), width :: number()) :: result :: number()
  def get(register, index, width) do
    head_length = index * width
    <<_head::bitstring-size(head_length), value::size(width), _tail::bitstring>> = register
    value
  end

  @doc """
  Set a specific bit in a register.
  """
  @spec put(t(), index :: number(), width :: number(), value :: number()) :: t()
  def put(register, index, width, value) do
    head_length = index * width
    <<head::bitstring-size(head_length), _former::size(width), tail::bitstring>> = register
    <<head::bitstring, value::size(width), tail::bitstring>>
  end

  @doc """
  Merge together two registers of the same width and type.
  """
  @spec merge(t(), t()) :: t()
  def merge(left, right),
    do: merge(left, right, <<>>)

  defp merge(<<v1, left::bitstring>>, <<v2, right::bitstring>>, acc),
    do: merge(left, right, <<acc::bitstring, max(v1, v2)>>)

  defp merge(<<>>, <<>>, acc),
    do: acc

  @doc """
  Run a reduction over the inner bits of a register.
  """
  @spec reduce(t(), width :: number(), accumulator :: any(), (number, any -> any)) ::
          accumulator :: any()
  def reduce(<<>>, _width, acc, _fun),
    do: acc

  def reduce(input, width, acc, fun) do
    <<head::size(width), rest::bitstring>> = input
    reduce(rest, width, fun.(head, acc), fun)
  end
end
