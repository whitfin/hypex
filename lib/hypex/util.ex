defmodule Hypex.Util do
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
  def apply_correction(_m, raw_estimate, _zero_count) when raw_estimate <= @max_uniques / 30 do
    raw_estimate
  end
  def apply_correction(_m, raw_estimate, _zero_count)  do
    -@max_uniques * :math.log(1 - raw_estimate / @max_uniques)
  end

  @doc """
  A small binary reducer to translate into an accumulator.

  This is to avoid having to convert a bitstring to a list in order to iterate
  effectively. This shaves off about half a millisecond of execution time when
  operating on a `b = 16` Hypex.
  """
  @spec binary_reduce(input :: bitstring, width :: number, accumulator :: any, function) :: accumulator :: any
  def binary_reduce(<<>>, _width, acc, _fun), do: acc
  def binary_reduce(input, width, acc, fun) do
    << head :: size(width), rest :: bitstring >> = input
    binary_reduce(rest, width, fun.(head, acc), fun)
  end

  @doc """
  Counts the leading zeroes in a bitstring.

  This is done by walking the entire bitstring until a non-zero is hit. This looks
  inefficient at a glance, but there are typically only one or two bits before we
  hit a zero.
  """
  @spec count_leading_zeros(input :: bitstring, count :: number) :: total :: number
  def count_leading_zeros(input, count \\ 1)
  def count_leading_zeros(<< 0 :: size(1), rest :: bitstring >>, count),
  do: count_leading_zeros(rest, count + 1)
  def count_leading_zeros(_input, count), do: count

  @doc """
  Simple accessor for the @hash_length constant.
  """
  @spec hash_length :: length :: number
  def hash_length, do: @hash_length

  @doc """
  Simple accessor for the @max_uniques constant.
  """
  @spec max_uniques :: combinations :: number
  def max_uniques, do: @max_uniques

  @doc """
  Normalizes an Atom to a Hypex register implementation.

  Because `Hypex.Array` holds the default implementations, we just check for any
  `Hypex.Bitstring` overrides at this point.
  """
  @spec normalize_module(module :: atom) :: normalized_module :: atom
  def normalize_module(mod) when mod in [ Array, Hypex.Array, nil ],
  do: Hypex.Array
  def normalize_module(mod) when mod in [ Bitstring, Hypex.Bitstring ],
  do: Hypex.Bitstring
  def normalize_module(mod) when is_atom(mod), do: mod

  @doc """
  Zips corresponding elements from each list in list_of_lists.

  This function acts in an identical way to `List.zip/1` except that the zipped
  values are lists rather than tuples. This is because Hypex merge performance
  can be improved without the jumps to/from Tuple structures.
  """
  @spec ziplist(lists :: [ ]) :: zipped_list :: []
  def ziplist(list_of_lists) when is_list(list_of_lists),
  do: zip(list_of_lists, [])

  # The internal zip of `ziplist/1`, accepting a list and an accumulator. This
  # function will move through each list and blend each index into a single list
  # in which each index is grouped as a list.
  #
  # This implementation contains slight optimizations for the Hypex use case vs
  # the implementation inside the `List` module.
  defp zip(list, acc) do
    case :lists.mapfoldl(&zip_each/2, [], list) do
      { _, nil } ->
        :lists.reverse(acc)
      { mlist, heads } ->
        zip(mlist, [heads | acc])
    end
  end

  # The handlers for the `:lists.mapfoldl/3` call inside `zip/2`. If we reach
  # the end of a list, we pass back a set of `nil` tuples to avoid continuing.
  defp zip_each([h | t], acc), do: { t, [h | acc] }
  defp zip_each(_lists, _acc), do: { nil, nil }

end
