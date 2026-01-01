default_width = 4

empty_arr_hypex = Hypex.new(default_width, Hypex.Register.Array)
empty_lst_hypex = Hypex.new(default_width, Hypex.Register.List)
empty_str_hypex = Hypex.new(default_width, Hypex.Register.Bitstring)

full_arr_hypex =
  Enum.reduce(0..500, empty_arr_hypex, fn val, acc ->
    Hypex.update(acc, "key_#{val}")
  end)

full_lst_hypex =
  Enum.reduce(0..500, empty_lst_hypex, fn val, acc ->
    Hypex.update(acc, "key_#{val}")
  end)

full_str_hypex =
  Enum.reduce(0..500, empty_str_hypex, fn val, acc ->
    Hypex.update(acc, "key_#{val}")
  end)

Benchee.run(
  %{
    "Array Hypex.new/1" => fn ->
      Hypex.new(default_width, Hypex.Register.Array)
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
      Hypex.new(default_width, Hypex.Register.Bitstring)
    end,
    "Bitstring Hypex.update/1" => fn ->
      Hypex.update(empty_str_hypex, "Hypex")
    end,
    "Bitstring Hypex.cardinality/1" => fn ->
      Hypex.cardinality(full_str_hypex)
    end,
    "Bitstring Hypex.merge/1" => fn ->
      Hypex.merge(empty_str_hypex, full_str_hypex)
    end,
    "List Hypex.new/1" => fn ->
      Hypex.new(default_width, Hypex.Register.List)
    end,
    "List Hypex.update/1" => fn ->
      Hypex.update(empty_lst_hypex, "Hypex")
    end,
    "List Hypex.cardinality/1" => fn ->
      Hypex.cardinality(full_lst_hypex)
    end,
    "List Hypex.merge/1" => fn ->
      Hypex.merge(empty_lst_hypex, full_lst_hypex)
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
