require 'colorize'
require 'logging'

require 'logger_util'

module Types
  #
  # Base class for all media type implementations
  #
  class Base
    include LoggerUtil

    DIFF_THRESHOLD_IN_MILLIS = 1000

    attr_reader :source_dir, :filename, :exif, :options

    def initialize(source_dir, filename, options)
      @source_dir = source_dir
      @filename = filename
      @exif = MiniExiftool.new(source_dir + filename)
      @options = options
    end

    #
    # Updates the 'mtime' for this media if it differs from the event time
    # by more than DIFF_THRESHOLD_IN_MILLIS
    #
    def update_mtime
      etime = event_time
      if etime
        mtime = File.mtime(source_dir + filename)
        diff = (mtime - etime).abs
        if diff > DIFF_THRESHOLD_IN_MILLIS
          FileUtils.touch(source_dir + filename, mtime: etime) unless test_mode?
          log(:debug, "Updated mtime for '#{filename}' to #{etime}")
          return 1
        else
          log(:debug, "event_time [#{etime}] and mtime [#{mtime}] are within threshold - #{'UPDATE NOT NEEDED'.blue}")
          return 0
        end
      else
        return -1
      end
    end

    #
    # Moves this file to the given destination directory under the following
    # directory structure convention:
    #
    # dest_dir
    #    |
    #     --- 2015
    #          |
    #           --- '2015-01 - january'
    #          |
    #           --- '2015-02 - february'
    #
    def move_file(dest_dir)
      etime = event_time
      if etime
        sub_dir = "#{etime.year}/#{etime.strftime('%Y-%m')} #{etime.strftime('%B').downcase}"
        dest_path = dest_dir + sub_dir
        unless test_mode?
          FileUtils.mkdir_p(dest_path)
          FileUtils.mv(source_dir + filename, dest_path)
        end
        log(:debug, "Moved '#{filename}' to '#{dest_path}'")
        return 1
      else
        return 0
      end
    end

    #
    # Returns the time when this media was taken
    #
    def event_time
      fail "'event_time' not implemented for #{self}"
    end

    def test_mode?
      options[:test_mode]
    end

    def log(level, message)
      log_message(level, message, options[:test_mode])
    end
  end
end
