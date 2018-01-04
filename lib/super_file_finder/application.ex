defmodule SuperFileFinder.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    
    # List all child processes to be supervised
    children = [
      worker(Finder.Searcher, [])
      # Starts a worker by calling: SuperFileFinder.Worker.start_link(arg)
      # {SuperFileFinder.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :simple_one_for_one, name: SuperFileFinder.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def new_worker(params) do
    Supervisor.start_child(SuperFileFinder.Supervisor, [fn -> Finder.Searcher.start_link(params) end])
  end

end
