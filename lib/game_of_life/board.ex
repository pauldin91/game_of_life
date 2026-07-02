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

  def game_over?(matrix) do
    sum = Enum.reduce(matrix, 0, fn x, acc -> acc + Enum.sum(x) end)

    cond do
      sum == 0 -> true
      true -> false
    end
  end
end
