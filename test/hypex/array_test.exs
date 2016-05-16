defmodule Hypex.ArrayTest do
  use PowerAssert, async: false

  alias Hypex.Array

  test "updating a Hypex with a value" do
    hypex = Hypex.new(4, Hypex.Array)
    hypex = Hypex.update(hypex, "Hypex")

    assert(hypex == { Array, 4, { :array, 16, 0, 0, { { 0, 0, 0, 0, 0, 3, 0, 0, 0, 0 }, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10 } } })
  end

  test "updating a Hypex with a duplicate value will short-circuit" do
    hypex = Hypex.new(16, Hypex.Array)

    { time1, hypex } = :timer.tc(fn ->
      Hypex.update(hypex, "Hypex")
    end)

    { time2, _hypex } = :timer.tc(fn ->
      Hypex.update(hypex, "Hypex")
    end)

    assert(time2 < time1 * 0.75)
  end

  test "cardinality correctly handles small ranges" do
    b = 4

    values = 150

    hypex = Enum.reduce(1..values, Hypex.new(b, Hypex.Array), &(Hypex.update(&2, &1)))

    assert(hypex |> Hypex.cardinality |> round == 101)
  end

  test "cardinality correctly handles medium ranges" do
    b = 8

    values_count = 1000

    hypex = Enum.reduce(1..values_count, Hypex.new(b, Hypex.Array), &(Hypex.update(&2, &1)))

    assert(hypex |> Hypex.cardinality |> round == 925)
  end

  test "cardinality correctly handles large ranges" do
    arr = binary_to_arr(10, TestHelper.read_large_registers())

    hypex = { Array, 10, arr }

    assert(hypex |> Hypex.cardinality |> round == 151253332)
  end

  test "cardinality is within a +/- 1.04 * sqrt(m) bounding" do
    b = 16

    values_count = 10000
    relative_error = 1.04 * :math.sqrt(TestHelper.calculate_m(b))

    hypex = Enum.reduce(1..values_count, Hypex.new(b, Hypex.Array), &(Hypex.update(&2, &1)))

    count = Hypex.cardinality(hypex)

    assert(count < (values_count + relative_error))
    assert(count > (values_count - relative_error))
  end

  test "cardinality with no zeros returns the estimate" do
    hypex = { Array, 4, binary_to_arr(4, << 30, 30, 67, 33, 34, 33, 65, 33 >>) }

    count = Hypex.cardinality(hypex)

    assert(count == 38.28518367014784)
  end

  defp binary_to_arr(width, bin) do
    width
    |> binary_to_bits(bin)
    |> :array.from_list(0)
    |> :array.fix
  end

  defp binary_to_bits(width, bin) do
    bin
    |> reduce([])
    |> Enum.chunk(width)
    |> Enum.map(fn(x) ->
        x
        |> Enum.join("")
        |> Integer.parse(2)
        |> Kernel.elem(0)
       end)
  end

  defp reduce(<<>>, acc), do: acc |> Enum.reverse
  defp reduce(b, acc) do
      << bit :: size(1), rest :: bitstring >> = b
      reduce(rest, [ bit | acc ])
  end

end
