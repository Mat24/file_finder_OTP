defmodule Finder.Searcher do
    use GenServer

    def start_link(name) do
        GenServer.start_link(__MODULE__, [], [name: name])
    end

    def init(initial_data) do
        {:ok, initial_data} 
    end

    # Backend
    def handle_call(message, _from, [] ) do
        {:reply, "Ready for file searching...", [acc: []]}
    end

    def handle_call

    
end