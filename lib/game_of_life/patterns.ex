defmodule GameOfLife.Patterns do
  @block [[1, 1], [1, 1]]

  @beehive [
    [0, 1, 1, 0],
    [1, 0, 0, 1],
    [0, 1, 1, 0]
  ]

  @loaf [
    [0, 1, 1, 0],
    [1, 0, 0, 1],
    [0, 1, 0, 1],
    [0, 0, 1, 0]
  ]

  @tub [
    [0, 1, 0],
    [1, 0, 1],
    [0, 1, 0]
  ]

  @blinker [[1, 1, 1]]

  @toad [
    [0, 0, 1, 1, 1, 0],
    [0, 1, 1, 1, 0, 0]
  ]

  @beacon [
    [1, 1, 0, 0],
    [1, 1, 0, 0],
    [0, 0, 1, 1],
    [0, 0, 1, 1]
  ]
  @glider [[0, 0, 1], [1, 0, 1], [0, 1, 1]]

  # still
  def block(), do: @block

  def beehive(), do: @beehive

  def loaf(), do: @loaf

  def tub(), do: @tub

  # oscilators
  def blinker(), do: @blinker

  def toad(), do: @toad

  def beacon(), do: @beacon

  # spaceships
  def glider(), do: @glider
end
