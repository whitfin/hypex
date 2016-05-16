ExUnit.start()

defmodule TestHelper do

  def calculate_m(b) do
    2
    |> :math.pow(b)
    |> round
    |> (&(&1 * b)).()
  end

  def read_files_r(root) do
    root
    |> File.ls!
    |> Enum.map(&(Path.join(root, &1)))
    |> Enum.reduce([], fn(path, paths) ->
        if File.dir?(path) do
          [read_files_r(path)|paths]
        else
          [path|paths]
        end
       end)
    |> List.flatten
  end

  def read_large_registers do
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
  end

end

__ENV__.file
|> Path.dirname
|> Path.join("hypex")
|> TestHelper.read_files_r
|> Enum.each(&(Code.require_file/1))
