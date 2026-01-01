empty_arr_hypex = Hypex.new(16, Hypex.Array)
empty_str_hypex = Hypex.new(16, Hypex.Bitstring)

full_arr_hypex =
  Enum.reduce(0..500, empty_arr_hypex, fn val, acc ->
    Hypex.update(acc, "key_#{val}")
  end)

full_str_hypex =
  Enum.reduce(0..500, empty_str_hypex, fn val, acc ->
    Hypex.update(acc, "key_#{val}")
  end)

Benchee.run(
  %{
    "Array Hypex.new/1" => fn ->
      Hypex.new(16, Hypex.Array)
    end,
    "Array Hypex.update/1" => fn ->
      Hypex.update(empty_arr_hypex, "Hypex")
    end,
    "Array Hypex.cardinality/1" => fn ->
      Hypex.cardinality(full_arr_hypex)
    end,
    "Array Hypex.merge/1" => fn ->
      Hypex.merge(empty_arr_hypex, full_arr_hypex)
    end,
    "Bitstring Hypex.new/1" => fn ->
      Hypex.new(16, Hypex.Bitstring)
    end,
    "Bitstring Hypex.update/1" => fn ->
      Hypex.update(empty_str_hypex, "Hypex")
    end,
    "Bitstring Hypex.cardinality/1" => fn ->
      Hypex.cardinality(full_str_hypex)
    end,
    "Bitstring Hypex.merge/1" => fn ->
      Hypex.merge(empty_str_hypex, full_str_hypex)
    end
  },
  formatters: [
    {
      Benchee.Formatters.Console,
      [
        comparison: false,
        extended_statistics: false
      ]
    }
  ],
  print: [
    fast_warning: false
  ]
)
