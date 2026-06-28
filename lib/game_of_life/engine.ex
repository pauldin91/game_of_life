defmodule GameOfLife.Engine do
  alias Finch.Pool.Strategy.Random

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

  def make_map(matrix, size),
    do:
      Enum.zip(
        0..(size * size - 1),
        Enum.reduce(matrix, [], fn x, acc -> acc ++ x end)
      )
      |> Map.new()

  def calculate_cell(the_map, i, size) do
    indices(i, size)
    |> Enum.map(fn i -> Map.get(the_map, i, 0) end)
    |> Enum.sum()
  end

  def indices(i, size) do
    r = rem(i, size)
    right = (i + 1 - size)..(i + 1 + size)//size |> Enum.map(& &1)
    left = (i - 1 - size)..(i - 1 + size)//size |> Enum.map(& &1)
    top = i - size
    bottom = i + size

    init = [top, bottom]

    init ++
      cond do
        r == 0 ->
          right

        r == size - 1 ->
          left

        true ->
          left ++ right
      end
  end

  def apply_rules(the_map, size) do
    Enum.map(the_map, fn
      {i, v} ->
        total = calculate_cell(the_map, i, size)

        cond do
          total == 3 ->
            {i, 1}

          2 <= total and total <= 3 and v == 1 ->
            {i, v}

          true ->
            {i, 0}
        end
    end)
  end

  def sum_row(row, the_map), do: Enum.map(row, fn x -> Map.get(the_map, x, 0) end) |> Enum.sum()
end
