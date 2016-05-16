defmodule HypexTest do
  use PowerAssert

  alias Hypex.Array
  alias Hypex.Bitstring

  test "creating a new default Hypex" do
    Enum.each(4..16, fn(x) ->
      m = TestHelper.calculate_m(x) |> (&(&1 / x)).() |> round
      r = magic_round(m)
      assert(Hypex.new(x) == { Array, x, { :array, m, 0, 0, r } })
    end)
  end

  test "creating a new Bitstring Hypex" do
    Enum.each(4..16, fn(x) ->
      m = TestHelper.calculate_m(x)
      assert(Hypex.new(x, Hypex.Bitstring) == { Bitstring, x, << 0 :: size(m) >> })
    end)
  end

  test "creating a new Array Hypex" do
    Enum.each(4..16, fn(x) ->
      m = TestHelper.calculate_m(x) |> (&(&1 / x)).() |> round
      r = magic_round(m)
      assert(Hypex.new(x, Hypex.Array) == { Array, x, { :array, m, 0, 0, r } })
    end)
  end

  test "creating a Hypex with a custom register" do
    hypex = Hypex.new(4, ListRegister)
    hypex = Hypex.update(hypex, "Hypex")

    assert(hypex == { ListRegister, 4, [0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] })
  end

  test "creating a new Hypex with no width defaults to using 16" do
    m = TestHelper.calculate_m(16) |> (&(&1 / 16)).() |> round
    r = magic_round(m)
    assert(Hypex.new() == { Array, 16, { :array, m, 0, 0, r } })
  end

  test "creating a new Hypex with a seed less than 4" do
    assert_raise(ArgumentError, "Invalid width provided, must be 16 >= width >= 4", fn ->
      Hypex.new(3)
    end)
  end

  test "creating a new Hypex with a seed greater than 6" do
    assert_raise(ArgumentError, "Invalid width provided, must be 16 >= width >= 4", fn ->
      Hypex.new(17)
    end)
  end

  test "creating a new Hypex with an invalid seed" do
    assert_raise(ArgumentError, "Invalid width provided, must be 16 >= width >= 4", fn ->
      Hypex.new("test")
    end)
  end

  test "updating an invalid Hypex" do
    assert_raise(ArgumentError, "Hypex.update/2 requires a valid Hypex instance", fn ->
      Hypex.update("test", "test")
    end)
  end

  test "cardinality on an invalid Hypex" do
    assert_raise(ArgumentError, "Hypex.cardinality/1 requires a valid Hypex instance", fn ->
      Hypex.cardinality("test")
    end)
  end

  test "merging a single Hypex instance" do
    h1 = Enum.reduce([ "one", "two", "three" ], Hypex.new(4, Hypex.Array), &(Hypex.update(&2, &1)))
    h2 = Hypex.merge([h1])

    assert(h1 == h2)
  end

  test "merging two Array Hypex instances" do
    h1 = Enum.reduce([ "one", "two", "three" ], Hypex.new(4, Hypex.Array), &(Hypex.update(&2, &1)))
    h2 = Enum.reduce([ "four", "five", "six" ], Hypex.new(4, Hypex.Array), &(Hypex.update(&2, &1)))

    assert(h1 == { Array, 4, { :array, 16, 0, 0, { { 2, 0, 1, 0, 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 2, 0, 0, 0, 0 }, 10, 10, 10, 10, 10, 10, 10, 10, 10 } } })
    assert(h2 == { Array, 4, { :array, 16, 0, 0, { { 0, 0, 0, 2, 0, 2, 0, 0, 0, 0 }, { 0, 2, 0, 0, 0, 0, 0, 0, 0, 0 }, 10, 10, 10, 10, 10, 10, 10, 10, 10 } } })

    h3 = Hypex.merge(h1, h2)

    assert(h3 == { Array, 4, { :array, 16, 0, 0, { { 2, 0, 1, 2, 0, 2, 0, 0, 0, 0 }, { 0, 2, 0, 0, 0, 2, 0, 0, 0, 0 }, 10, 10, 10, 10, 10, 10, 10, 10, 10 } } })
  end

  test "merging a list of Array Hypex instances" do
    h1 = Enum.reduce([ "one", "two", "three" ], Hypex.new(4, Hypex.Array), &(Hypex.update(&2, &1)))
    h2 = Enum.reduce([ "four", "five", "six" ], Hypex.new(4, Hypex.Array), &(Hypex.update(&2, &1)))
    h3 = Enum.reduce([ "seven", "eight", "nine" ], Hypex.new(4, Hypex.Array), &(Hypex.update(&2, &1)))

    assert(h1 == { Array, 4, { :array, 16, 0, 0, { { 2, 0, 1, 0, 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 2, 0, 0, 0, 0 }, 10, 10, 10, 10, 10, 10, 10, 10, 10 } } })
    assert(h2 == { Array, 4, { :array, 16, 0, 0, { { 0, 0, 0, 2, 0, 2, 0, 0, 0, 0 }, { 0, 2, 0, 0, 0, 0, 0, 0, 0, 0 }, 10, 10, 10, 10, 10, 10, 10, 10, 10 } } })
    assert(h3 == { Array, 4, { :array, 16, 0, 0, { { 0, 0, 0, 0, 0, 0, 2, 2, 0, 0 }, { 2, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, 10, 10, 10, 10, 10, 10, 10, 10, 10 } } })

    h4 = Hypex.merge([h1, h2, h3])

    assert(h4 == { Array, 4, { :array, 16, 0, 0, { { 2, 0, 1, 2, 0, 2, 2, 2, 0, 0 }, { 2, 2, 0, 0, 0, 2, 0, 0, 0, 0 }, 10, 10, 10, 10, 10, 10, 10, 10, 10}} })
  end

  test "merging two Bitstring Hypex instances" do
    h1 = Enum.reduce([ "one", "two", "three" ], Hypex.new(4, Hypex.Bitstring), &(Hypex.update(&2, &1)))
    h2 = Enum.reduce([ "four", "five", "six" ], Hypex.new(4, Hypex.Bitstring), &(Hypex.update(&2, &1)))

    assert(h1 == { Bitstring, 4, << 32, 16, 0, 0, 0, 0, 0, 2 >> })
    assert(h2 == { Bitstring, 4, <<  0,  2, 2, 0, 0, 2, 0, 0 >> })

    h3 = Hypex.merge(h1, h2)

    assert(h3 == { Bitstring, 4, << 32, 16, 2, 0, 0, 2, 0, 2 >> })
  end

  test "merging a list of Bitstring Hypex instances" do
    h1 = Enum.reduce([ "one", "two", "three" ], Hypex.new(4, Hypex.Bitstring), &(Hypex.update(&2, &1)))
    h2 = Enum.reduce([ "four", "five", "six" ], Hypex.new(4, Hypex.Bitstring), &(Hypex.update(&2, &1)))
    h3 = Enum.reduce([ "seven", "eight", "nine" ], Hypex.new(4, Hypex.Bitstring), &(Hypex.update(&2, &1)))

    assert(h1 == { Bitstring, 4, << 32, 16, 0,  0, 0,  0, 0, 2 >> })
    assert(h2 == { Bitstring, 4, <<  0,  2, 2,  0, 0,  2, 0, 0 >> })
    assert(h3 == { Bitstring, 4, <<  0,  0, 0, 34, 0, 32, 0, 0 >> })

    h4 = Hypex.merge([h1, h2, h3])

    assert(h4 == { Bitstring, 4, << 32, 16, 2, 34, 0, 32, 0, 2 >> })
  end

  test "merging a list of differently typed Hypex instances" do
    h1 = Enum.reduce([ "one", "two", "three" ], Hypex.new(4, Hypex.Array), &(Hypex.update(&2, &1)))
    h2 = Enum.reduce([ "four", "five", "six" ], Hypex.new(4, Hypex.Bitstring), &(Hypex.update(&2, &1)))

    assert(h1 == { Array, 4, { :array, 16, 0, 0, { { 2, 0, 1, 0, 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 2, 0, 0, 0, 0 }, 10, 10, 10, 10, 10, 10, 10, 10, 10 } } })
    assert(h2 == { Bitstring, 4, <<  0,  2, 2,  0, 0,  2, 0, 0 >> })

    assert_raise(ArgumentError, "Merging requires valid Hypex structures of the same width and type", fn ->
      Hypex.merge([h1, h2])
    end)
  end

  test "merging a list of Hypex instances with different widths" do
    assert_raise(ArgumentError, "Merging requires valid Hypex structures of the same width and type", fn ->
      h1 = Hypex.new(4)
      h2 = Hypex.new(5)

      Hypex.merge([h1, h2])
    end)
  end

  test "merging a list of invalid instances" do
    assert_raise(ArgumentError, "Merging requires valid Hypex structures of the same width and type", fn ->
      Hypex.merge("test")
    end)
  end

  defp magic_round(x) do
    :math.pow(10, (x |> to_string |> byte_size)) |> round
  end

end

defmodule ListRegister do
  @behaviour Hypex.Register

  # initialize
  def init(width),
  do: Enum.reduce(1..:erlang.bsl(1, width), [], fn(_, l) -> [ 0 | l ] end)

  # no-op
  def from_list(bits), do: bits

  # no-op
  def to_list(registers), do: registers

  # value retrieval
  def get_value(registers, idx, _width),
  do: Enum.at(registers, idx)

  # value modification
  def set_value(registers, idx, _width, value),
  do: List.replace_at(registers, idx, value)

  # reduction
  def reduce(registers, _width, acc, fun),
  do: Enum.reduce(registers, acc, fun)

end
