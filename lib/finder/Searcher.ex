defmodule Finder.Searcher do
    use GenServer
    alias SuperFileFinder, as: SFinder

    def start_link(params \\ %{list: [], num_workers: 0,
                              principal_process_pid: nil,
                              invoker_pid: nil}) do
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

    def reducer([], _params, parent_pid, invoker_pid, acc) do
        GenServer.cast(parent_pid, {:end_process, acc, parent_pid})
        # Kill process pending  
    end

    def reducer([file | tail], params, parent_pid, invoker_pid, acc) do

        %{path: path, filename: filename} = params
        case File.dir?(file) do
            true ->
                new_path = Path.join(path, file)
                {:ok, pid} = Supervisor.start_child(
                                SFinder.Supervisor,
                                [%{list: [], num_workers: 0,
                                principal_process_pid: parent_pid,
                                invoker_pid: invoker_pid}])
                find(pid, %{path: new_path, filename: filename}, invoker_pid)
                reducer(tail, params, parent_pid, invoker_pid, acc)

            false when file == filename -> 
                reducer(
                    tail, params, parent_pid,
                    invoker_pid, ["#{path}/#{filename}"| acc]
                )

            false -> reducer(tail, params, parent_pid, invoker_pid, acc)
        end
    end

    def handle_cast({:find, params, invoker_pid}, status) do

        principal_process_pid = case status[:principal_process_pid] do
            nil -> self()
            _ -> status[:principal_process_pid]
        end

        add_worker(principal_process_pid)
        
        %{path: path, filename: filename} = params
        dir_content =  case File.ls(path) do
            {:ok, result} -> result
            {:error, _} -> []
        end

        reducer(dir_content, params, principal_process_pid, invoker_pid, [])
        
        {:noreply, 
            %{ status | principal_process_pid: principal_process_pid,
            invoker_pid: invoker_pid }
        }        
    end

    def handle_cast({:end_process, result_list, parent_pid}, result ) do
        minus_worker(parent_pid)
        cond do
            parent_pid == self() -> nil
            true -> 
            case check_num_workers(parent_pid) do
                0 -> send(result[:invoker_pid], {:ok, result})
                _ -> nil # Task still don't complete
            end
        end

        IO.puts("Inspect result chain (#{inspect parent_pid}) : "<>
                "#{inspect result}")
        
        {:noreply, %{result | list: [result_list | result[:list]]}}
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
    
end