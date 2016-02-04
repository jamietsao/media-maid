require_relative 'base'

module Types
  #
  # MOV media handler
  #
  class MOV < Base
    #
    # Returns the time when this MOV video was taken
    #
    def event_time
      log(:debug, "#{filename.green}")
      log(:debug, "#{'ContentCreateDate:'.ljust(30)} #{exif['ContentCreateDate']}")
      log(:debug, "#{'CreateDate:'.ljust(30)} #{exif['CreateDate']}")
      log(:debug, "#{'FileModifyDate:'.ljust(30)} #{exif['FileModifyDate']}")
      exif['ContentCreateDate'] ? exif['ContentCreateDate'] : exif['CreateDate']
    end
  end
end
