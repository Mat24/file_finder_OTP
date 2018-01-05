defmodule Finder.Searcher do
    use GenServer

    def start_link(params \\ %{list: [], num_workers: 0, principal_process_pid: nil}) do
        GenServer.start_link(__MODULE__, params)
    end

    def init(initial_data) do
        IO.puts "Starting..#{inspect self()} data: #{inspect initial_data}"
        {:ok, initial_data} 
    end

    def add_worker(pid) do
        GenServer.cast(pid, {:add_worker})
    end

    def minus_worker(pid) do
        GenServer.cast(pid, {:minus_worker})
    end

    def check_num_workers(pid) do
        GenServer.call(pid, {:check_num_workers})
    end

    def find(pid, params, god_pid) do
        GenServer.cast(pid, {:find, params, god_pid})
    end

    def reducer([], _params, parent_pid, acc) do
        GenServer.cast(parent_pid, {:end_process, acc, parent_pid})
        #Supervisor.terminate_child(SuperFileFinder.Supervisor, self())
        #send parent_pid, {:ok, acc}
        #Process.exit(self(), :normal)
        # Notificar al padre de que termino y darle el resultado    
    end

    def reducer([file | tail], params, parent_pid, acc) do

        #Debug
        #IO.puts("Inspecting... #{inspect file}")

        %{path: path, filename: filename} = params
        case File.dir?(file) do
            true ->
                new_path = Path.join(path, file)
                {:ok, pid} = Supervisor.start_child(SuperFileFinder.Supervisor, [%{list: [], num_workers: 0, principal_process_pid: parent_pid}])
                find(pid, %{path: new_path, filename: filename}, parent_pid)
                reducer(tail, params, parent_pid, acc)
            false when file == filename -> reducer(tail, params, parent_pid, ["#{path}/#{filename}"| acc])
            false -> reducer(tail, params, parent_pid, acc)          
        end
    end

    # Backend
    def handle_cast({:find, params, god_pid}, status) do

        principal_process_pid = case status[:principal_process_pid] do
            nil -> self()
            _ -> status[:principal_process_pid]
        end

        add_worker(principal_process_pid)
        
        #aca esta la magia
        %{path: path, filename: filename} = params
        dir_content =  case File.ls(path) do
            {:ok, result} -> result
            {:error, _} -> []
        end

        #Debug
        #IO.inspect dir_content

        reducer(dir_content, params, principal_process_pid, [])
        {:noreply, %{ status | principal_process_pid: principal_process_pid}}        
    end

    def handle_cast({:end_process, result_list, parent_pid}, result ) do
        minus_worker(parent_pid)
        cond do
            parent_pid == self() -> nil
            true -> 
                case check_num_workers(parent_pid) do
                    0 -> send(parent_pid, {:ok, result})
                    _ -> nil # No ha termiando
                end
        end
        #IO.puts("Process (#{inspect parent_pid}) end with: #{result_list}")
        IO.puts("Inspect result chain (#{inspect parent_pid}) : #{inspect result}")

        
        {:noreply, %{result | list: [result_list | result[:list]]}}
        #{:noreply,%{list: [result_list | result[:list]], num_workers: result[:num_workers]}
    end

    def handle_cast({:add_worker}, result) do
        add_worker = result[:num_workers] + 1
        {:noreply, %{result | num_workers: add_worker}}
    end

    def handle_cast({:minus_worker}, result) do
        minus_worker = result[:num_workers] - 1
        {:noreply, %{result | num_workers: minus_worker}}
    end

    def handle_call({:check_num_workers}, _from, result) do
        {:reply, result[:num_workers], result}
    end

    #Finder.Searcher.process_result(parent_pid,[...])
    
end