defmodule Hypex do
  use Bitwise

  @moduledoc """
  This module provides an Elixir implementation of HyperLogLog as described within
  http://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf. Current implementation
  works with an underlying bitstring which acts as the registers in the algorithm.

  A Hypex instance is simply a two-element Tuple, which provides a slight speed
  improvement over using a struct (roughly 10% at last benchmark). This tuple
  should only ever be constructed via `Hypex.new/1` otherwise you run the risk of
  pattern matching errors throughout modification.
  """

  # alias internal modules
  alias Hypex.Util

  # our hash size in bits
  @hash_length 32

  # the maximum uniques allowed by the hash
  @max_uniques 1 <<< @hash_length

  # cardinality error
  @card2_err "Hypex.cardinality/1 requires a valid Hypex instance"

  # merge error
  @merge_err "Merging requires valid Hypex structures of the same width"

  # invalid construction error
  @range_err "Invalid width provided, must be 16 >= width >= 4"

  # update error
  @update_err "Hypex.update/2 requires a valid Hypex instance"

  # define the Hypex typespec
  @type hypex :: { number, bitstring }

  @doc """
  Create a new Hypex using a width `b` when `16 >= b >= 4`.

  We determine the number of internal registers based on `b` as `m` when `m` is
  equivalent to `2 ^ b`. We then initialize `m` registers with 0 bits and return
  a Tuple of `{ b, registers }`.

  ## Examples

      iex> Hypex.new(4)
      { 4, << 0, 0, 0, 0, 0, 0, 0, 0 >> }

  """
  @spec new(number) :: hypex
  def new(b \\ 16)
  def new(b) when is_integer(b) and b <= 16 and b >= 4 do
    m = (1 <<< b) * b
    { b, << 0 :: size(m) >> }
  end
  def new(_b) do
    raise ArgumentError, message: @range_err
  end

  @doc """
  Calculates a cardinality based upon a passed in Hypex.

  We use a binary reduce function internally to make this as cheap as possible and
  we use only a single pass (even if it's a little worse for memory). Corrections
  are applied per the algorithm definition to account to the bit size of the hash
  function.

  ## Examples

      iex> hypex = Hypex.new(4)
      iex> hypex = Hypex.update(hypex, "one")
      iex> hypex = Hypex.update(hypex, "two")
      iex> hypex = Hypex.update(hypex, "three")
      iex> Hypex.cardinality(hypex) |> round
      3

  """
  @spec cardinality(hypex) :: number
  def cardinality({ b, _registers } = hypex) do
    m = 1 <<< b

    { helper, zeroes } = binary_reduce(hypex, { 0, 0 }, fn(int, { helper, zeroes }) ->
      { 1 / (1 <<< int) + helper, int == 0 && zeroes + 1 || zeroes }
    end)

    raw_estimate = a(m) * m * m * 1 / helper

    apply_correction(zeroes, m, raw_estimate)
  end
  def cardinality(_hypex) do
    raise ArgumentError, message: @card2_err
  end

  @doc """
  Merges together many Hypex instances with the same seed.

  This is done in a readable way as opposed to a performant way as it will be only
  rarely called. We zip up the two input bitstrings and reduce them into a single
  bitstring, taking the max bit from either and folding it into the reduction.

  ## Examples

      iex> h1 = Hypex.new(4)
      iex> h1 = Hypex.update(h1, "one")
      iex> h1 = Hypex.update(h1, "two")
      iex> h2 = Hypex.new(4)
      iex> h2 = Hypex.update(h2, "three")
      iex> h3 = Hypex.merge([h1, h2])
      iex> Hypex.cardinality(h3) |> round
      3

  """
  @spec merge([ hypex ]) :: hypex
  def merge([ { b, _registers } | _ ] = hypices) do
    unless Enum.all?(hypices, &(match?({ ^b, _ }, &1))) do
      raise ArgumentError, message: @merge_err
    end

    registers = Enum.map(hypices, fn({ ^b, registers }) ->
      :erlang.bitstring_to_list(registers)
    end)

    m_reg = registers |> Util.ziplist |> Enum.reduce(<<>>, fn(bits, register) ->
      register <> << :lists.max(bits) >>
    end)

    { b, m_reg }
  end
  def merge(_hypices) do
    raise ArgumentError, message: @merge_err
  end

  @doc """
  Merges together two Hypex instances with the same seed.

  Internally this function just wraps the two instances in a list and passes them
  throguh to `merge/1`.
  """
  @spec merge(hypex, hypex) :: hypex
  def merge(h1, h2),
  do: merge([ h1, h2 ])

  @doc """
  Updates a Hypex instance with a value.

  Internally `:erlang.phash2/2` is used as a 32-bit hash function due to it being
  both readily available and relatively fast. Everything here is done via pattern
  matching to achieve fast speeds.

  The main performance hit of this function comes when there's a need to modify
  a bit inside the bitstring, so we protect against doing this unnecessarily by
  pre-determining whether the modification will be a no-op.

  ## Examples

      iex> 4 |> Hypex.new |> Hypex.update("one")
      { 4, << 0, 0, 0, 0, 0, 0, 0, 2 >> }

  """
  @spec update(hypex, any) :: hypex
  def update({ b, registers } = hypex, value) do
    << idx :: size(b), rest :: bitstring >> = << :erlang.phash2(value, @max_uniques) :: size(@hash_length) >>

    head_length = idx * b
    << head :: bitstring-size(head_length), current_value :: size(b), tail :: bitstring >> = registers

    case max(current_value, count_leading_zeros(rest)) do
      ^current_value ->
        hypex
      new_value ->
        { b, << head :: bitstring, new_value :: size(b), tail :: bitstring >> }
    end
  end
  def update(_hypex, _value) do
    raise ArgumentError, message: @update_err
  end

  # Defines the value of `a` per the algorithm definition, with special casing
  # for when `m` is any of 16, 32 or 64. Anything higher than 128 is calculated
  # in a general way using the algorithm implementation.
  defp a(16), do: 0.673
  defp a(32), do: 0.697
  defp a(64), do: 0.709
  defp a(m) when m >= 128, do: 0.7213 / (1 + 1.079 / m)

  # Applies a correction to the raw esimation based on the size of the raw estimate.
  # The three function heads apply corrections for small/medium/large ranges (top-down).
  defp apply_correction(zero_count, m, raw_estimate) when raw_estimate <= 5 * m / 2 do
    case zero_count do
      0 -> raw_estimate
      z -> m * :math.log(m / z)
    end
  end
  defp apply_correction(_zero_count, _m, raw_estimate) when raw_estimate <= @max_uniques / 30 do
    raw_estimate
  end
  defp apply_correction(_zero_count, _m, raw_estimate)  do
    -@max_uniques * :math.log(1 - raw_estimate / @max_uniques)
  end

  # A small binary reducer to avoid having to convert a bitstring to a list in
  # order to iterate effectively. This shaves off about half a millisecond of
  # execution time when operating on a `b = 16` Hypex.
  defp binary_reduce({ b, registers }, acc, fun) do
    binary_reduce(b, registers, acc, fun)
  end
  defp binary_reduce(_b, <<>>, acc, _fun), do: acc
  defp binary_reduce(b, registers, acc, fun) do
    << head :: size(b), rest :: bitstring >> = registers
    binary_reduce(b, rest, fun.(head, acc), fun)
  end

  # Counts the leading zeros in a bitstring by walking the entire bitstring. This
  # sounds horribly expensive but typically a non-zero is hit within a few calls.
  defp count_leading_zeros(registers, count \\ 1)
  defp count_leading_zeros(<< 0 :: size(1), rest :: bitstring >>, count),
  do: count_leading_zeros(rest, count + 1)
  defp count_leading_zeros(_registers, count), do: count

end
