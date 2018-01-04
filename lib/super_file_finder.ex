defmodule SuperFileFinder do
  
  def file_finder([path: path, filename: filename]) do
    SuperFileFinder.Application.new_worker([])
  end

  def file_finder([]) do
    SuperFileFinder.Application.new_worker([])
  end
end
