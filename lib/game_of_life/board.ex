defmodule GameOfLife.Board do

  def new_board(_size, "custom") do
    Map.new()
  end

  def new_board(%{"rows"=>rows,"cols"=>cols}, "random") do
    r = 0..(rows * cols - 1)

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

  def indices(i, rows, cols) do
    r = rem(i, cols)
    right = get_side(i + 1, cols)
    left = get_side(i - 1, cols)

    [i - cols, i + cols] ++
      cond do
        r == 0 -> right
        r == cols - 1 -> left
        true -> left ++ right
      end
    |> Enum.filter(fn idx -> idx >= 0 and idx < rows * cols end)
  end

  def calculate_cell(the_map, i, rows, cols) do
    indices(i, rows, cols)
    |> Enum.map(fn i -> Map.get(the_map, i, 0) end)
    |> Enum.sum()
  end
end
