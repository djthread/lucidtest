defmodule Lucidtest.BoardChannel do
  use Lucidtest.Web, :channel
  alias Lucidtest.Board

  def join("board", _junk, socket) do
    {:ok, socket}
  end

  def handle_in("hash", _msg, socket) do
    {:reply, elem(Board.state, 0), socket}
  end

  def handle_in("state", _msg, socket) do
    {:reply, Board.state, socket}
  end

  def handle_in("add_card", n, socket) do
    {:reply, Board.add_card(n), socket}
  end

  def handle_in("randomize_card", idx, socket) do
    {:reply, Board.randomize_card(idx), socket}
  end
end
