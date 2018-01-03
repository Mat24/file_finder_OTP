defmodule SuperFileFinder do
  
  def file_finder([path: path, filename: filename]) do
    GenServer.call(Finder.Searcher, [path: path, filename: filename])
  end
end
