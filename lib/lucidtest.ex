defmodule Lucidtest do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Lucidtest.Endpoint, []),
      supervisor(Lucidtest.Board, []),
    ]

    opts = [strategy: :one_for_one, name: Lucidtest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Lucidtest.Endpoint.config_change(changed, removed)
    :ok
  end
end
