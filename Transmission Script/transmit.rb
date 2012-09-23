#!/usr/bin/ruby
require "FileUtils"

destination_folder = "/Users/oceania/Sites/giftwrap/process"
valid_extensions   = ["mkv", "2t", "avi"]

class Giftwrap
  attr_accessor :download_folder,
                :torrent_filename,
                :valid_extensions,
                :destination_folder

  def initialize(download_folder, torrent_filename)
    @download_folder = download_folder
    @torrent_filename = torrent_filename

    @torrent = @download_folder + "/" + @torrent_filename

    @found_video = Array.new
  end

  def go
    if self.is_directory?
      Dir.foreach(@torrent) do |file|
        self.find_biggest_video_file(file)
      end
    elsif
      self.move(@torrent, destination_folder)
    end
  end

  def move(source, destination)
    FileUtils.move source, destination
  end

  def is_video?(filename)
    matches = filename.match(/\.([a-z0-9]+)$/i)

    if !matches
      return false
    end

    ext = matches[1]
    @valid_extensions.include?(ext)
  end

  def find_biggest_video_file(filename)
    if self.is_video?(filename)
      video_file = @torrent + "/" + filename
      self.move video_file, @destination_folder
    end
  end

  def is_directory?
    if File.exists?(@torrent) && File.directory?(@torrent)
        return true
    end
    return false
  end

end

gw = Giftwrap.new(ENV["TR_TORRENT_DIR"], ENV["TR_TORRENT_NAME"])
gw.valid_extensions = valid_extensions
gw.destination_folder = destination_folder
gw.go
