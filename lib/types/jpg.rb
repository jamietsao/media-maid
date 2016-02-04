require_relative 'base'

module Types
  #
  # JPG media handler
  #
  class JPG < Base
    #
    # Returns the time when this JPG image was taken
    #
    def event_time
      log(:debug, "#{filename.green}")
      log(:debug, "#{'DateTimeOriginal:'.ljust(30)} #{exif['DateTimeOriginal']}")
      log(:debug, "#{'FileModifyDate:'.ljust(30)} #{exif['FileModifyDate']}")
      exif['DateTimeOriginal']
    end
  end
end
