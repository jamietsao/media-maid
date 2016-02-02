require 'colorize'
require 'mini_exiftool'
require 'thor'
require 'yaml'

#
# Media Maid CLI
#
class MediaMaidCLI < Thor
  IGNORE_LIST = %w(. .. .DS_Store .picasa.ini)
  DIFF_THRESHOLD_IN_MILLIS = 1000

  class_option :verbose, type: :boolean, default: true
  class_option :test, type: :boolean, default: true

  desc 'fix_mtime SOURCE_DIR', 'Updates the file\'s mtime to the file\'s "event_date" for all media in the SOURCE_DIR'
  def fix_mtime(source_dir)
    missing, not_needed, fixed = 0, 0, 0
    Dir.foreach(source_dir) do |file|
      next if IGNORE_LIST.include? file
      result = update_mtime(source_dir, file)
      case result
      when 1
        fixed += 1
      when 0
        not_needed += 1
      when -1
        missing += 1
      end
    end
    log "SUMMARY --> Fixed: #{fixed.to_s.green} Not Needed: #{not_needed.to_s.green} Missing: #{missing.to_s.green}", true
  end

  desc 'organize SOURCE_DIR DEST_DIR', 'Organizes all media in the given SOURCE_DIR to the given DEST_DIR using a date-based directory structure'
  def organize(source_dir, dest_dir)
    count, skipped = 0, 0
    Dir.foreach(source_dir) do |file|
      next if IGNORE_LIST.include? file
      result = move_file(source_dir, file, dest_dir)
      if result == 1
        count += 1
      else
        skipped += 1
      end
    end
    log "SUMMARY --> Moved #{count.to_s.green} files from #{source_dir} to #{dest_dir}. Skipped: #{skipped.to_s.green}", true
  end

  private

  def update_mtime(source_dir, file)
    event_time = get_event_time(source_dir, file)
    if event_time
      mtime = File.mtime(source_dir + file)
      diff = (mtime - event_time).abs
      if diff > DIFF_THRESHOLD_IN_MILLIS
        FileUtils.touch(source_dir + file, mtime: event_time) unless options[:test]
        log "Updated mtime for #{file} to #{event_time}"
        return 1
      else
        log "event_time [#{event_time}] and mtime [#{mtime}] for are within threshold - #{'FIX NOT NEEDED'.blue}"
        return 0
      end
    else
      return -1
    end
  end

  def move_file(source_dir, filename, dest_dir)
    event_time = get_event_time(source_dir, filename)
    if event_time
      sub_dir = "#{event_time.year}/#{event_time.strftime('%Y-%m')}-#{event_time.strftime('%B').downcase}"
      unless options[:test]
        FileUtils.mkdir_p(dest_dir + sub_dir)
        FileUtils.mv(source_dir + filename, dest_dir + sub_dir)
      end
      log "Moved #{filename} to #{dest_dir + sub_dir}"
      return 1
    else
      return 0
    end
  end

  def get_event_time(source_dir, filename)
    event_time = nil
    file_path = source_dir + filename
    if filename.downcase.end_with?('jpg')
      exif = MiniExiftool.new(file_path)
      log "#{filename.green}"
      log "#{'DateTimeOriginal:'.ljust(30)} #{exif['DateTimeOriginal']}"
      log "#{'FileModifyDate:'.ljust(30)} #{exif['FileModifyDate']}"
      event_time = exif['DateTimeOriginal']
    elsif filename.downcase.end_with?('mov')
      exif = MiniExiftool.new(file_path)
      log "#{filename.green}"
      log "#{'ContentCreateDate:'.ljust(30)} #{exif['ContentCreateDate']}"
      log "#{'CreateDate:'.ljust(30)} #{exif['CreateDate']}"
      log "#{'FileModifyDate:'.ljust(30)} #{exif['FileModifyDate']}"
      event_time = exif['ContentCreateDate'] ? exif['ContentCreateDate'] : exif['CreateDate']
    else
      log "#{filename.green} #{'UNRECOGNIZED FILE TYPE'.red}"
    end
    event_time
  end

  def log(message, output = nil)
    puts "#{options[:test] ? '[TEST MODE] '.magenta : ''}#{message}" if output || options[:verbose]
  end
end
