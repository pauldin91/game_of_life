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

  def drop(matrix, i, j, pattern) do
    do_replace(matrix, i - 1, j - 1, pattern)
  end

  def do_replace(matrix, i, j, pattern) do
    size = Enum.count(Enum.at(matrix, 0))
    patterns_size = Enum.count(Enum.at(pattern, 0))

    pat =
      make_map(
        pattern,
        patterns_size,
        i * size + j,
        size
      )

    mat = make_map(matrix, size, 0, size)

    res =
      Enum.map(mat, fn {x, y} ->
        repl = Map.get(pat, x, nil)

        cond do
          repl == nil -> {x, y}
          true -> {x, repl}
        end
      end)
      |> Enum.sort(fn e1, e2 -> elem(e1, 0) < elem(e2, 0) end)
      |> Enum.map(fn {_i, v} -> v end)
      |> Enum.chunk_every(length(matrix))

    {:ok, res}
  end

  defp make_map(matrix, size, offset, global_mat_size) do
    Enum.zip(
      Enum.with_index(
        offset..(offset + length(matrix) * size - 1)
        |> Enum.chunk_every(size)
      )
      |> Enum.map(fn {x, i} -> x |> Enum.map(fn y -> y + i * (global_mat_size - size) end) end)
      |> Enum.reduce([], fn x, acc -> acc ++ x end),
      Enum.reduce(matrix, [], fn x, acc -> acc ++ x end)
    )
    |> Map.new(fn {k, v} ->
      {k, v}
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
    size = Enum.count(Enum.at(matrix, 0))

    Enum.zip(
      0..(length(matrix) * size - 1),
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
