defmodule GameOfLife.Board do

  def new_board(_size, "custom") do
    Map.new()
  end

  def new_board(size, "random") do
    r = 0..(size * size - 1)

    Enum.zip(
      r,
      Enum.map(r, fn _ -> :rand.uniform(2) - 1 end)
    )
    |> Enum.filter(fn {_x, y} -> y == 1 end)
    |> Map.new()
  end

  defp get_side(start, step) do
    (start - step)..(start + step)//step |> Enum.map(& &1)
  end

  def indices(i, size) do
    r = rem(i, size)
    right = get_side(i + 1, size)
    left = get_side(i - 1, size)

    [i - size, i + size] ++
      cond do
        r == 0 -> right
        r == size - 1 -> left
        true -> left ++ right
      end
  end

  def calculate_cell(the_map, i, size) do
    indices(i, size)
    |> Enum.map(fn i -> Map.get(the_map, i, 0) end)
    |> Enum.sum()
  end
end
