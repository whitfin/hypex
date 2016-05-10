defmodule HypexTest do
  use PowerAssert
  doctest Hypex

  test "creating a new Hypex" do
    Enum.each(4..16, fn(x) ->
      m = calculate_m(x)
      assert(match?({ ^x, << 0 :: size(m) >> }, Hypex.new(x)))
    end)
  end

  test "creating a new Hypex with no seed defaults to using 16" do
    m = calculate_m(16)
    assert(match?({ 16, << 0 :: size(m) >> }, Hypex.new()))
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

  test "updating a Hypex with a value" do
    hypex = Hypex.new(4)
    hypex = Hypex.update(hypex, "Hypex")

    assert(hypex == { 4, <<0, 0, 3, 0, 0, 0, 0, 0>> })
  end

  test "updating a Hypex with a duplicate value will short-circuit" do
    hypex = Hypex.new(16)

    { time1, hypex } = :timer.tc(fn ->
      Hypex.update(hypex, "Hypex")
    end)

    { time2, _hypex } = :timer.tc(fn ->
      Hypex.update(hypex, "Hypex")
    end)

    assert(time2 < time1 / 2)
  end

  test "updating an invalid Hypex" do
    assert_raise(ArgumentError, "Hypex.update/2 requires a valid Hypex instance", fn ->
      Hypex.update("test", "test")
    end)
  end

  test "cardinality correctly handles small ranges" do
    b = 4

    values = 150

    hypex = Enum.reduce(1..values, Hypex.new(b), &(Hypex.update(&2, &1)))

    assert(hypex |> Hypex.cardinality |> round == 101)
  end

  test "cardinality correctly handles medium ranges" do
    b = 8

    values_count = 1000

    hypex = Enum.reduce(1..values_count, Hypex.new(b), &(Hypex.update(&2, &1)))

    assert(hypex |> Hypex.cardinality |> round == 925)
  end

  test "cardinality correctly handles large ranges" do
    bin =
      __ENV__.file
      |> Path.dirname
      |> Path.join("resources")
      |> Path.join("large_registers.txt")
      |> File.read!
      |> String.split(",")
      |> Enum.map(fn(bit) ->
          bit
          |> String.strip
          |> Integer.parse
          |> Kernel.elem(0)
         end)
      |> :erlang.list_to_bitstring

    hypex = { 10, bin }

    assert(hypex |> Hypex.cardinality |> round == 151253332)
  end

  test "cardinality is within a +/- 1.04 * sqrt(m) bounding" do
    b = 16

    values_count = 10000
    relative_error = 1.04 * :math.sqrt(calculate_m(b))

    hypex = Enum.reduce(1..values_count, Hypex.new(b), &(Hypex.update(&2, &1)))

    count = Hypex.cardinality(hypex)

    assert(count < (values_count + relative_error))
    assert(count > (values_count - relative_error))
  end

  test "cardinality with no zeros returns the estimate" do
    hypex = { 4, << 30, 30, 67, 33, 34, 33, 65, 33 >> }

    count = Hypex.cardinality(hypex)

    assert(count == 38.28518367014784)
  end

  test "cardinality on an invalid Hypex" do
    assert_raise(ArgumentError, "Hypex.cardinality/1 requires a valid Hypex instance", fn ->
      Hypex.cardinality("test")
    end)
  end

  test "merging two Hypex instances" do
    h1 = Enum.reduce([ "one", "two", "three" ], Hypex.new(4), &(Hypex.update(&2, &1)))
    h2 = Enum.reduce([ "four", "five", "six" ], Hypex.new(4), &(Hypex.update(&2, &1)))

    assert(h1 == { 4, << 32, 16, 0, 0, 0, 0, 0, 2 >> })
    assert(h2 == { 4, <<  0,  2, 2, 0, 0, 2, 0, 0 >> })

    h3 = Hypex.merge(h1, h2)

    assert(h3 == { 4, << 32, 16, 2, 0, 0, 2, 0, 2 >> })
  end

  test "merging a list of Hypex instances" do
    h1 = Enum.reduce([ "one", "two", "three" ], Hypex.new(4), &(Hypex.update(&2, &1)))
    h2 = Enum.reduce([ "four", "five", "six" ], Hypex.new(4), &(Hypex.update(&2, &1)))
    h3 = Enum.reduce([ "seven", "eight", "nine" ], Hypex.new(4), &(Hypex.update(&2, &1)))

    assert(h1 == { 4, << 32, 16, 0,  0, 0,  0, 0, 2 >> })
    assert(h2 == { 4, <<  0,  2, 2,  0, 0,  2, 0, 0 >> })
    assert(h3 == { 4, <<  0,  0, 0, 34, 0, 32, 0, 0 >> })

    h4 = Hypex.merge([h1, h2, h3])

    assert(h4 == { 4, << 32, 16, 2, 34, 0, 32, 0, 2 >> })
  end

  test "merging a list of invalid instances" do
    assert_raise(ArgumentError, "Merging requires valid Hypex structures of the same width", fn ->
      Hypex.merge("test")
    end)
  end

  test "merging a list of Hypex instances with different widths" do
    assert_raise(ArgumentError, "Merging requires valid Hypex structures of the same width", fn ->
      h1 = Hypex.new(4)
      h2 = Hypex.new(5)

      Hypex.merge(h1, h2)
    end)
  end

  defp calculate_m(b) do
    2
    |> :math.pow(b)
    |> round
    |> (&(&1 * b)).()
  end

end
