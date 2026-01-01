defmodule Hypex.Utilities do
  @moduledoc false
  # Provides internal tooling which doesn't fit into the main Hypex module. This
  # module shall remain undocumented as the specifics of this module should not
  # be relied upon and may change at any time.

  # our hash size in bits
  @hash_length 32

  # the maximum uniques allowed by the hash
  @max_uniques :erlang.bsl(1, @hash_length)

  @doc """
  Defines the value of `a` per the algorithm definition.

  We have special casing for when `m` is any of 16, 32 or 64. Anything higher than
  128 is calculated in a general way using the algorithm implementation.
  """
  @spec a(m :: number) :: a :: number
  def a(16), do: 0.673
  def a(32), do: 0.697
  def a(64), do: 0.709
  def a(m) when m >= 128, do: 0.7213 / (1 + 1.079 / m)

  @doc """
  Applies a correction to an estimation based upon the size of the raw estimate
  and the number of potential hashes we can see.

  The three function heads here apply corrections for small/medium/large ranges
  (from the top down).
  """
  @spec apply_correction(m :: number, estimate :: number, zero_count :: number) :: result :: number
  def apply_correction(m, raw_estimate, zero_count) when raw_estimate <= 5 * m / 2 do
    case zero_count do
      0 -> raw_estimate
      z -> m * :math.log(m / z)
    end
  end

  def apply_correction(_m, raw_estimate, _zero_count) when raw_estimate <= @max_uniques / 30,
    do: raw_estimate

  def apply_correction(_m, raw_estimate, _zero_count),
    do: -@max_uniques * :math.log(1 - raw_estimate / @max_uniques)

  @doc """
  Counts the leading zeroes in a bitstring.

  This is done by walking the entire bitstring until a non-zero is hit. This looks
  inefficient at a glance, but there are typically only one or two bits before we
  hit a zero.
  """
  @spec count_leading_zeros(input :: bitstring, count :: number) :: total :: number
  def count_leading_zeros(input, count \\ 1)

  def count_leading_zeros(<<0::size(1), rest::bitstring>>, count),
    do: count_leading_zeros(rest, count + 1)

  def count_leading_zeros(_input, count), do: count

  @doc """
  Simple accessor for the @hash_length constant.
  """
  @spec hash_length :: length :: number
  def hash_length,
    do: @hash_length

  @doc """
  Simple accessor for the @max_uniques constant.
  """
  @spec max_uniques :: combinations :: number
  def max_uniques,
    do: @max_uniques
end
