defmodule Lucidtest.BoardChannel do
  use Lucidtest.Web, :channel
  alias Lucidtest.Board
  require Logger

  def join("board", _junk, socket) do
    {:ok, socket}
  end

  def handle_in("hash", _msg, socket) do
    {:reply, {:ok, elem(Board.state, 0)}, socket}
  end

  def handle_in("state", _msg, socket) do
    {:reply, {:ok, Board.state}, socket}
  end

  def handle_in("add_card", n, socket) do
    response = Board.add_card(n)

    bc! "board", "add_card", response

    {:reply, {:ok, response}, socket}
  end

  def handle_in("add_random_card", _msg, socket) do
    response = Board.add_random_card

    bc! "board", "add_random_card", response
    Logger.debug "add_random_card!! " <> inspect(response)

    {:reply, {:ok, response}, socket}
  end

  def handle_in("randomize_card", idx, socket) do
    response = Board.randomize_card(idx)

    bc! "board", "randomize_card", response

    {:reply, {:ok, response}, socket}
  end

  defp bc!(topic, event, msg) do
    unless msg == :noop do
      Lucidtest.Endpoint.broadcast!(topic, event, msg)
    end
  end
end
