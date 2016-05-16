defmodule Hypex do
  @moduledoc """
  This module provides an Elixir implementation of HyperLogLog as described within
  http://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf. Various implementations
  are provided in order to account for performance and memory optimizations.

  A Hypex instance is simply a three-element Tuple, which provides a slight speed
  improvement over using a struct (roughly 10% at last benchmark). This tuple
  should only ever be constructed via `Hypex.new/2` otherwise you run the risk of
  pattern matching errors throughout modification.
  """

  # alias some internals
  alias Hypex.Util

  # cardinality error
  @card2_err "Hypex.cardinality/1 requires a valid Hypex instance"

  # merge error
  @merge_err "Merging requires valid Hypex structures of the same width and type"

  # invalid construction error
  @range_err "Invalid width provided, must be 16 >= width >= 4"

  # update error
  @update_err "Hypex.update/2 requires a valid Hypex instance"

  @typedoc """
  A Hypex interface structure
  """
  @opaque t :: { mod :: term, width :: number, register :: Register.t }

  @doc """
  Create a new Hypex using a width when `16 >= width >= 4`.

  The type of register is determined by the module backing the Hypex instance.
  We normalize to ensure we have a valid module and then initialize the module
  with the widths.

  Once the registers are initialized, we return them inside a Tuple alongside
  the width and module name.

  ## Examples

      iex> Hypex.new(4)
      { Hypex.Array, 4, { :array, 16, 0, 0, 100 } }

      iex> Hypex.new(4, Bitstring)
      { Hypex.Bitstring, 4, << 0, 0, 0, 0, 0, 0, 0, 0 >> }

  """
  @spec new(width :: number) :: hypex :: Hypex.t
  def new(width \\ 16, mod \\ nil)
  def new(width, mod) when is_integer(width) and width <= 16 and width >= 4 do
    impl = Util.normalize_module(mod)
    { impl, width, impl.init(width) }
  end
  def new(_width, _mod) do
    raise ArgumentError, message: @range_err
  end

  @doc """
  Calculates a cardinality based upon a passed in Hypex.

  We use the reduce function of the module representing the registers, and track
  the number of zeroes alongside the initial value needed to create a raw estimate.

  Once we have these values we just apply the correction by using the `m` value,
  the zero count, and the raw estimate.

  ## Examples

      iex> hypex = Hypex.new(4)
      iex> hypex = Hypex.update(hypex, "one")
      iex> hypex = Hypex.update(hypex, "two")
      iex> hypex = Hypex.update(hypex, "three")
      iex> Hypex.cardinality(hypex) |> round
      3

  """
  @spec cardinality(hypex :: Hypex.t) :: cardinality :: number
  def cardinality({ mod, width, registers } = _hypex) do
    m = :erlang.bsl(1, width)

    { value, zeroes } = mod.reduce(registers, width, { 0, 0 }, fn(int, { current, zeroes }) ->
      { 1 / :erlang.bsl(1, int) + current, int == 0 && zeroes + 1 || zeroes }
    end)

    raw_estimate = Util.a(m) * m * m * 1 / value

    Util.apply_correction(m, raw_estimate, zeroes)
  end
  def cardinality(_hypex) do
    raise ArgumentError, message: @card2_err
  end

  @doc """
  Merges together many Hypex instances with the same seed.

  This is done by converting the underlying register structure to a list of bits
  and taking the max of each index into a new list, before converting back into
  the register structure.

  We accept an arbitrary number of Hypex instances to merge and due to the use
  of List zipping this comes naturally. We catch empty and single entry Lists to
  avoid wasting computation.

  If you have a scenario in which you have to merge a lot of Hypex structures,
  you should typically buffer up your merges and then pass them all as a list to
  this function. This is far more efficient than merging two structures repeatedly.

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
  @spec merge([ hypex :: Hypex.t ]) :: hypex :: Hypex.t
  def merge([ { _mod, _width, _registers } = hypex ]),
  do: hypex
  def merge([ { mod, width, _registers } | _ ] = hypices) do
    unless Enum.all?(hypices, &(match?({ ^mod, ^width, _ }, &1))) do
      raise ArgumentError, message: @merge_err
    end

    registers = Enum.map(hypices, fn({ mod, _width, registers }) ->
      mod.to_list(registers)
    end)

    m_reg =
      registers
      |> Util.ziplist
      |> Enum.reduce([], &([ :lists.max(&1) | &2 ]))
      |> Enum.reverse
      |> mod.from_list

    { mod, width, m_reg }
  end
  def merge(_hypices) do
    raise ArgumentError, message: @merge_err
  end

  @doc """
  Merges together two Hypex instances with the same seed.

  Internally this function just wraps the two instances in a list and passes them
  throguh to `merge/1`.
  """
  @spec merge(hypex :: Hypex.t, hypex :: Hypex.t) :: hypex :: Hypex.t
  def merge(h1, h2),
  do: merge([ h1, h2 ])

  @doc """
  Updates a Hypex instance with a value.

  Internally `:erlang.phash2/2` is used as a 32-bit hash function due to it being
  both readily available and relatively fast. Everything here is done via pattern
  matching to achieve fast speeds.

  The main performance hit of this function comes when there's a need to modify
  a bit inside the register, so we protect against doing this unnecessarily by
  pre-determining whether the modification will be a no-op.

  ## Examples

      iex> 4 |> Hypex.new(Bitstring) |> Hypex.update("one")
      { Hypex.Bitstring, 4, << 0, 0, 0, 0, 0, 0, 0, 2 >> }

  """
  @spec update(hypex :: Hypex.t, value :: any) :: hypex :: Hypex.t
  def update({ mod, width, registers } = hypex, value) do
    max_uniques = Util.max_uniques()
    hash_length = Util.hash_length()

    << idx :: size(width), rest :: bitstring >> = << :erlang.phash2(value, max_uniques) :: size(hash_length) >>

    current_value = mod.get_value(registers, idx, width)

    case max(current_value, Util.count_leading_zeros(rest)) do
      ^current_value ->
        hypex
      new_value ->
        { mod, width, mod.set_value(registers, idx, width, new_value) }
    end
  end
  def update(_hypex, _value) do
    raise ArgumentError, message: @update_err
  end

end
