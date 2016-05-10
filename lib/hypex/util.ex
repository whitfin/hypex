defmodule Hypex.Util do
  @moduledoc false
  # Provides internal tooling which doesn't fit into the main Hypex module. This
  # module shall remain undocumented as the specifics of this module should not
  # be relied upon and may change at any time.

  @doc """
  Zips corresponding elements from each list in list_of_lists.

  This function acts in an identical way to `List.zip/1` except that the zipped
  values are lists rather than tuples. This is because Hypex merge performance
  can be improved without the jumps to/from Tuple structures.
  """
  def ziplist(list_of_lists) when is_list(list_of_lists),
  do: zip(list_of_lists, [])

  # The internal zip of `ziplist/1`, accepting a list and an accumulator. This
  # function will move through each list and blend each index into a single list
  # in which each index is grouped as a list.
  #
  # This implementation contains slight optimizations for the Hypex use case vs
  # the implementation inside the `List` module.
  defp zip(list, acc) do
    case :lists.mapfoldl(&zip_each/2, [], list) do
      { _, nil } ->
        :lists.reverse(acc)
      { mlist, heads } ->
        zip(mlist, [heads | acc])
    end
  end

  # The handlers for the `:lists.mapfoldl/3` call inside `zip/2`. If we reach
  # the end of a list, we pass back a set of `nil` tuples to avoid continuing.
  defp zip_each(_, nil), do: { nil, nil }
  defp zip_each([h | t], acc), do: { t, [h | acc] }
  defp zip_each([], _), do: { nil, nil }

end
