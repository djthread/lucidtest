defmodule Lucidtest.Board do
  @moduledoc """
  GenServer module to hold the current board state. The state data structure is
  a tuple where the first element is a hash that uniquely identifies the board
  state, and the second is a list of integers.
  """
  use GenServer
  require Logger

  @name __MODULE__
  @card_options 5

  @type board :: [integer]
  @type state :: {String.t, board}

  @spec start_link :: GenServer.on_start
  def start_link do
    GenServer.start_link(@name, [], name: @name)
  end

  def state,               do: GenServer.call(@name, :state)
  def add_card(n),         do: GenServer.call(@name, {:add_card, n})
  def add_random_card,     do: GenServer.call(@name, :add_random_card)
  def randomize_card(idx), do: GenServer.call(@name, {:randomize_card, idx})

  @spec init([]) :: {:ok, any}
  def init([]) do
    {:ok, [] |> state_by_board}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add_card, n}, _from, state)
  when is_integer(n) and n >= 1 and n <= @card_options
  do
    state =
      state
      |> elem(1)
      |> Enum.concat([n])
      |> state_by_board

    {:reply, %{hash: elem(state, 0), card: n}, state}
  end

  def handle_call({:add_card, bad_input}, _from, state) do
    {:reply, :noop, state}
  end

  def handle_call(:add_random_card, _from, state) do
    random_card = get_random_card

    state =
      state
      |> elem(1)
      |> Enum.concat([random_card])
      |> state_by_board

    Logger.debug "(#{length elem(state, 1)}) " <> (state |> elem(1) |> Enum.map(&to_string/1) |> Enum.join(" "))

    {:reply, %{hash: elem(state, 0), card: random_card}, state}
  end

  def handle_call({:randomize_card, idx}, _from, state) do
    random_card = get_random_card

    state =
      state
      |> elem(1)
      |> List.replace_at(idx, random_card)
      |> state_by_board

    {:reply, %{hash: elem(state, 0), idx: idx, card: random_card}, state}
  end

  @spec hash(board) :: String.t
  def hash(board) do
    serialized =
      Enum.reduce(board, "", fn(x, acc) ->
        acc <> Integer.to_string(x)
      end)

    hash =
      :md5  #:sha256
      |> :crypto.hash(serialized)
      |> Base.encode16
      |> String.downcase

    Logger.debug "tohash: \"#{serialized}\" -> #{hash}"

    hash
  end

  @spec state_by_board(board) :: state
  def state_by_board(board) do
    {hash(board), board}
  end

  @spec get_random_card :: integer
  def get_random_card do
    Enum.random(1..@card_options)
  end
end
