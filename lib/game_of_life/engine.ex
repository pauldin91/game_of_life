defmodule GameOfLife.Engine do
  @doc """
  Apply the rules of Conway's Game of Life to a grid of cells
  """

  def new_board(size) do
    0..(size - 1)
    |> Enum.map(fn _ ->
      0..(size - 1)
      |> Enum.map(fn _ -> :rand.uniform(2) - 1 end)
    end)
  end

  @spec tick(matrix :: list(list(0 | 1))) :: list(list(0 | 1))
  def tick([]), do: []

  def tick(matrix) do
    size = length(matrix)

    make_map(matrix, size)
    |> apply_rules(size)
    |> Enum.sort(fn e1, e2 -> elem(e1, 0) < elem(e2, 0) end)
    |> Enum.map(fn {_i, v} -> v end)
    |> Enum.chunk_every(size)
  end

  def game_over?(matrix) do
    sum = Enum.reduce(matrix, 0, fn x, acc -> acc + Enum.sum(x) end)

    cond do
      sum == 0 -> true
      true -> false
    end
  end

  def toggle_cell(matrix, i, j) do
    size = length(matrix)

    Enum.zip(
      0..(size * size - 1),
      Enum.reduce(matrix, [], fn x, acc -> acc ++ x end)
    )
    |> Enum.map(fn {x, y} ->
      cond do
        i * size + j == x -> 1 - y
        true -> y
      end
    end)
    |> Enum.chunk_every(size)
  end

  defp make_map(matrix, size),
    do:
      Enum.zip(
        0..(size * size - 1),
        Enum.reduce(matrix, [], fn x, acc -> acc ++ x end)
      )
      |> Map.new()

  defp get_side(start, step) do
    (start - step)..(start + step)//step |> Enum.map(& &1)
  end

  defp indices(i, size) do
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

  defp apply_rules(the_map, size) do
    Enum.map(the_map, fn
      {i, v} ->
        total = calculate_cell(the_map, i, size)

        cond do
          total == 3 -> {i, 1}
          2 <= total and total <= 3 and v == 1 -> {i, v}
          true -> {i, 0}
        end
    end)
  end

  defp calculate_cell(the_map, i, size) do
    indices(i, size)
    |> Enum.map(fn i -> Map.get(the_map, i, 0) end)
    |> Enum.sum()
  end
end
