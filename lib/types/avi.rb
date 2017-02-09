require_relative 'base'

module Types
  #
  # AVI media handler
  #
  class AVI < Base
    #
    # Returns the time when this AVI movie was taken
    #
    def event_time
      log(:debug, "#{filename.green}")
      log(:debug, "#{'DateTimeOriginal:'.ljust(30)} #{exif['DateTimeOriginal']}")
      log(:debug, "#{'FileModifyDate:'.ljust(30)} #{exif['FileModifyDate']}")
      exif['DateTimeOriginal']
    end
  end
end
