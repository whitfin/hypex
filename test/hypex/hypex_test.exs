defmodule Hypex.RegisterTest do
  import Hypex

  use ExUnit.Case,
    async: true,
    parameterize: [
      %{mod: Hypex.Register.Array},
      %{mod: Hypex.Register.Bitstring},
      %{mod: Hypex.Register.List}
    ]

  test "creating a new default Hypex" do
    assert Hypex.new() == Hypex.new(8)
  end

  test "creating a new default Hypex using a custom width" do
    refute Hypex.new(4) == Hypex.new(8)
  end

  test "creating a new modular Hypex", %{mod: mod} do
    assert Hypex.new(16, mod) == Hypex.new(16, mod)
  end

  test "merging a single Hypex instance", %{mod: mod} do
    hypex = Hypex.new(4, mod)

    left = Enum.reduce(["one", "two", "three"], hypex, &hupdate/2)
    right = Hypex.merge([left])

    assert left == right
  end

  test "merging two Hypex instances", %{mod: mod} do
    base = Hypex.new(8, mod)

    h1 = Enum.reduce(["one", "two", "three"], base, &hupdate/2)
    h2 = Enum.reduce(["four", "five", "six"], base, &hupdate/2)

    assert Hypex.cardinality(h1) == 3.017716672522796
    assert Hypex.cardinality(h2) == 3.017716672522796

    cardinality =
      [h1, h2]
      |> Hypex.merge()
      |> Hypex.cardinality()

    assert cardinality == 6.0714308140329125
  end

  defp hupdate(value, hypex) do
    Hypex.update(hypex, value)
  end

  test "merging a list of Hypex instances", %{mod: mod} do
    base = Hypex.new(8, mod)

    h1 = Enum.reduce(["one", "two", "three"], base, &hupdate/2)
    h2 = Enum.reduce(["four", "five", "six"], base, &hupdate/2)
    h3 = Enum.reduce(["seven", "eight", "nine"], base, &hupdate/2)

    assert Hypex.cardinality(h1) == 3.017716672522796
    assert Hypex.cardinality(h2) == 3.017716672522796
    assert Hypex.cardinality(h3) == 3.017716672522796

    cardinality =
      [h1, h2, h3]
      |> Hypex.merge()
      |> Hypex.cardinality()

    assert cardinality == 9.162011610005834
  end

  test "cardinality correctly handles small ranges", %{mod: mod} do
    b = 4
    hypex = Hypex.new(b, mod)
    values = 150

    cardinality =
      1..values
      |> Enum.reduce(hypex, &Hypex.update(&2, &1))
      |> Hypex.cardinality()
      |> round()

    assert cardinality == 101
  end

  test "cardinality correctly handles medium ranges", %{mod: mod} do
    b = 8
    hypex = Hypex.new(b, mod)
    values = 1000

    cardinality =
      1..values
      |> Enum.reduce(hypex, &Hypex.update(&2, &1))
      |> Hypex.cardinality()
      |> round()

    assert cardinality == 925
  end

  test "cardinality correctly handles large ranges", %{mod: mod} do
    arr = convert_bitstring_register(mod, 10, read_large_register())
    hypex = hypex(mod: mod, width: 10, register: arr)

    cardinality =
      hypex
      |> Hypex.cardinality()
      |> round()

    assert cardinality == 151_253_332
  end

  test "cardinality is within a +/- 1.04 * sqrt(m) bounding", %{mod: mod} do
    b = 16
    hypex = Hypex.new(b, mod)
    values = 10000
    relative = 1.04 * :math.sqrt(calculate_m(b))

    cardinality =
      1..values
      |> Enum.reduce(hypex, &Hypex.update(&2, &1))
      |> Hypex.cardinality()

    assert cardinality < values + relative
    assert cardinality > values - relative
  end

  test "cardinality with no zeros returns the estimate", %{mod: mod} do
    hypex =
      hypex(
        mod: mod,
        width: 4,
        register: convert_bitstring_register(mod, 4, <<30, 30, 67, 33, 34, 33, 65, 33>>)
      )

    assert Hypex.cardinality(hypex) == 38.28518367014784
  end

  defp calculate_m(b) do
    2
    |> :math.pow(b)
    |> round
    |> (&(&1 * b)).()
  end

  defp convert_bitstring_register(Hypex.Register.Array, width, input) do
    Hypex.Register.List
    |> convert_bitstring_register(width, input)
    |> :array.from_list(0)
    |> :array.fix()
  end

  defp convert_bitstring_register(Hypex.Register.Bitstring, _width, input) do
    input
  end

  defp convert_bitstring_register(Hypex.Register.List, width, input) do
    input
    |> reduce([])
    |> Enum.chunk_every(width)
    |> Enum.map(fn x ->
      x
      |> Enum.join("")
      |> Integer.parse(2)
      |> Kernel.elem(0)
    end)
  end

  defp reduce(<<>>, acc), do: acc |> Enum.reverse()

  defp reduce(b, acc) do
    <<bit::size(1), rest::bitstring>> = b
    reduce(rest, [bit | acc])
  end

  defp read_large_register do
    __ENV__.file
    |> Path.dirname()
    |> Path.dirname()
    |> Path.join("resources")
    |> Path.join("large_register.txt")
    |> File.read!()
    |> String.split(",")
    |> Enum.map(fn bit ->
      bit
      |> String.trim()
      |> Integer.parse()
      |> Kernel.elem(0)
    end)
    |> :erlang.list_to_bitstring()
  end
end
