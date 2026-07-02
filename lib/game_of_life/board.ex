defmodule GameOfLife.Board do
  defstruct [:size, :mode]

  def new_board(size, "custom") do
    0..(size - 1)
    |> Enum.map(fn _ ->
      0..(size - 1)
      |> Enum.map(fn _ -> 0 end)
    end)
  end

  def new_board(size, "random") do
    0..(size - 1)
    |> Enum.map(fn _ ->
      0..(size - 1)
      |> Enum.map(fn _ -> :rand.uniform(2) - 1 end)
    end)
  end

  def alive(matrix), do: Enum.reduce(matrix, 0, fn x, acc -> acc + Enum.sum(x) end)

  def game_over?(matrix) do
    sum = alive(matrix)

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
end
