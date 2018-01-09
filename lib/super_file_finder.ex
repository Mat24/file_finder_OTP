defmodule SuperFileFinder do
  
  def file_finder(%{path: path, filename: filename}) do
    {:ok, init_pid} = Supervisor.start_child(SuperFileFinder.Supervisor, [])
    Finder.Searcher.find(init_pid, %{path: path, filename: filename}, self())

    receive do
      {:ok, result} -> IO.puts "Work Node has been finished with: #{result}"
    end
  end
  
end 
