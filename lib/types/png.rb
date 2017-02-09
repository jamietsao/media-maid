require_relative 'base'

module Types
  #
  # PNG media handler
  #
  class PNG < Base
    #
    # PNGs do not have EXIF data for date created so attempt to determine
    # date via the filename. This should really only work for iPhone screenshot
    # PNGs that I've synced to the cloud via Camera Sync, where I'm using their
    # file naming standard of using the date.
    #
    def event_time
      # log(:debug, "#{filename.green}")
      # log(:debug, "#{'DateTimeOriginal:'.ljust(30)} #{exif['DateTimeOriginal']}")
      # log(:debug, "#{'FileModifyDate:'.ljust(30)} #{exif['FileModifyDate']}")
      # exif['DateTimeOriginal']
    end
  end
end
