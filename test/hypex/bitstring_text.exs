defmodule Hypex.BitstringTest do
  use ExUnit.Case, async: false

  alias Hypex.Bitstring

  test "updating a Hypex with a value" do
    hypex = Hypex.new(4, Hypex.Bitstring)
    hypex = Hypex.update(hypex, "Hypex")

    assert(hypex == { Bitstring, 4, <<0, 0, 3, 0, 0, 0, 0, 0>> })
  end

  test "updating a Hypex with a duplicate value will short-circuit" do
    hypex = Hypex.new(16)

    { time1, _hypex } = :timer.tc(fn ->
      for _ <- 1..1000 do
        Hypex.update(hypex, "Hypex")
      end
    end)

    hypex = Hypex.update(hypex, "Hypex")

    { time2, _hypex } = :timer.tc(fn ->
      for _ <- 1..1000 do
        Hypex.update(hypex, "Hypex")
      end
    end)

    assert(time2 < time1 * 0.75)
  end

  test "cardinality correctly handles small ranges" do
    b = 4

    values = 150

    hypex = Enum.reduce(1..values, Hypex.new(b, Hypex.Bitstring), &(Hypex.update(&2, &1)))

    assert(hypex |> Hypex.cardinality |> round == 101)
  end

  test "cardinality correctly handles medium ranges" do
    b = 8

    values_count = 1000

    hypex = Enum.reduce(1..values_count, Hypex.new(b, Hypex.Bitstring), &(Hypex.update(&2, &1)))

    assert(hypex |> Hypex.cardinality |> round == 925)
  end

  test "cardinality correctly handles large ranges" do
    hypex = { Bitstring, 10, TestHelper.read_large_registers() }

    assert(hypex |> Hypex.cardinality |> round == 151253332)
  end

  test "cardinality is within a +/- 1.04 * sqrt(m) bounding" do
    b = 16

    values_count = 10000
    relative_error = 1.04 * :math.sqrt(TestHelper.calculate_m(b))

    hypex = Enum.reduce(1..values_count, Hypex.new(b, Hypex.Bitstring), &(Hypex.update(&2, &1)))

    count = Hypex.cardinality(hypex)

    assert(count < (values_count + relative_error))
    assert(count > (values_count - relative_error))
  end

  test "cardinality with no zeros returns the estimate" do
    hypex = { Bitstring, 4, << 30, 30, 67, 33, 34, 33, 65, 33 >> }

    count = Hypex.cardinality(hypex)

    assert(count == 38.28518367014784)
  end

end
