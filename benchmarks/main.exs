init_width = 8

init_hypex = fn mod ->
  hypex = Hypex.new(init_width, mod)

  {
    hypex,
    Enum.reduce(0..25000, hypex, fn val, acc ->
      Hypex.update(acc, "key_#{val}")
    end)
  }
end

{empty_arr_hypex, full_arr_hypex} = init_hypex.(Hypex.Register.Array)
{empty_str_hypex, full_str_hypex} = init_hypex.(Hypex.Register.Bitstring)
{empty_lst_hypex, full_lst_hypex} = init_hypex.(Hypex.Register.List)
{empty_map_hypex, full_map_hypex} = init_hypex.(Hypex.Register.Map)
{empty_tpl_hypex, full_tpl_hypex} = init_hypex.(Hypex.Register.Tuple)

Benchee.run(
  %{
    "Array Hypex.new/1" => fn ->
      Hypex.new(init_width, Hypex.Register.Array)
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
      Hypex.new(init_width, Hypex.Register.Bitstring)
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
      Hypex.new(init_width, Hypex.Register.List)
    end,
    "List Hypex.update/1" => fn ->
      Hypex.update(empty_lst_hypex, "Hypex")
    end,
    "List Hypex.cardinality/1" => fn ->
      Hypex.cardinality(full_lst_hypex)
    end,
    "List Hypex.merge/1" => fn ->
      Hypex.merge(empty_lst_hypex, full_lst_hypex)
    end,
    "Map Hypex.new/1" => fn ->
      Hypex.new(init_width, Hypex.Register.Map)
    end,
    "Map Hypex.update/1" => fn ->
      Hypex.update(empty_map_hypex, "Hypex")
    end,
    "Map Hypex.cardinality/1" => fn ->
      Hypex.cardinality(full_map_hypex)
    end,
    "Map Hypex.merge/1" => fn ->
      Hypex.merge(empty_map_hypex, full_map_hypex)
    end,
    "Tuple Hypex.new/1" => fn ->
      Hypex.new(init_width, Hypex.Register.Tuple)
    end,
    "Tuple Hypex.update/1" => fn ->
      Hypex.update(empty_tpl_hypex, "Hypex")
    end,
    "Tuple Hypex.cardinality/1" => fn ->
      Hypex.cardinality(full_tpl_hypex)
    end,
    "Tuple Hypex.merge/1" => fn ->
      Hypex.merge(empty_tpl_hypex, full_tpl_hypex)
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
