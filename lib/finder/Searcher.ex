defmodule Finder.Searcher do
    use GenServer

    def start_link do
        GenServer.start_link(__MODULE__, [])
    end

    def init(initial_data) do
        IO.puts "Starting..."
        {:ok, initial_data} 
    end

    def find(pid, params, god_pid) do
        GenServer.cast(pid, {:find, params, god_pid})
    end

    def reducer([], _params, parent_pid, acc) do
        #GenServer.cast(parent_pid, {:end_process, acc})
        send parent_pid, {:ok, acc}
        acc
        # Notificar al padre de que termino y darle el resultado    
    end

    def reducer([file | tail], params, parent_pid, acc) do

        #Debug
        #IO.puts("Inspecting... #{file}")

        %{path: path, filename: filename} = params
        case File.dir?(file) do
            true ->
                new_path = Path.join(path, file)
                {:ok, pid} = Supervisor.start_child(SuperFileFinder.Supervisor, [])
                find(pid, %{path: new_path, filename: filename}, parent_pid)
                reducer(tail, params, parent_pid, acc)
            false when file == filename -> reducer(tail, params, parent_pid, ["#{path}/#{filename}"| acc])
            false -> reducer(tail, params, parent_pid, acc)          
        end
    end

    # Backend
    def handle_cast({:find, params, god_pid}, status) do
        #aca esta la magia
        %{path: path, filename: filename} = params
        dir_content =  case File.ls(path) do
            {:ok, result} -> result
            {:error, _} -> []
        end

        #Debug
        #IO.inspect dir_content

        reducer(dir_content, params, god_pid, [])
        {:noreply, :ok}        
    end

    def handle_cast({:end_process, result_list}, result ) do
        IO.puts("Process end with: #{result_list}")
        {:noreply, [result | result_list]}
    end

    #Finder.Searcher.process_result(parent_pid,[...])
    
end