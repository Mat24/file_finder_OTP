defmodule Finder.Searcher do
    use GenServer

    def start_link(options) do
        GenServer.start_link(__MODULE__, options)
    end

    def init(initial_data) do
        {:ok, initial_data} 
    end

    def get_result(pid) do
        GenServer.call(pid, {:get_result})
    end

    # Backend
    def handle_call({:get_result}, _from, result ) do
        {:reply, result, result}
    end
    
end