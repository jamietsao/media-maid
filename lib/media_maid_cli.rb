require 'colorize'
require 'logging'
require 'mini_exiftool'
require 'thor'

#
# Media Maid CLI
#
class MediaMaidCLI < Thor
  IGNORE_LIST = %w(. .. .DS_Store .picasa.ini)
  DIFF_THRESHOLD_IN_MILLIS = 1000

  def initialize(*args)
    super
    init_logger
  end

  class_option :log_file, type: :string
  class_option :log_level, type: :string, default: 'debug'
  class_option :test_mode, type: :boolean, default: true

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
    log(:info, "SUMMARY --> Fixed: #{fixed.to_s.green} Not Needed: #{not_needed.to_s.green} Missing: #{missing.to_s.green}")
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
    log(:info, "SUMMARY --> Moved #{count.to_s.green} files from #{source_dir} to #{dest_dir}. Skipped: #{skipped.to_s.green}")
  end

  private

  def update_mtime(source_dir, file)
    event_time = get_event_time(source_dir, file)
    if event_time
      mtime = File.mtime(source_dir + file)
      diff = (mtime - event_time).abs
      if diff > DIFF_THRESHOLD_IN_MILLIS
        FileUtils.touch(source_dir + file, mtime: event_time) unless options[:test_mode]
        log(:debug, "Updated mtime for #{file} to #{event_time}")
        return 1
      else
        log(:debug, "event_time [#{event_time}] and mtime [#{mtime}] for are within threshold - #{'FIX NOT NEEDED'.blue}")
        return 0
      end
    else
      return -1
    end
  end

  def move_file(source_dir, filename, dest_dir)
    event_time = get_event_time(source_dir, filename)
    if event_time
      sub_dir = "#{event_time.year}/#{event_time.strftime('%Y-%m')} #{event_time.strftime('%B').downcase}"
      unless options[:test_mode]
        FileUtils.mkdir_p(dest_dir + sub_dir)
        FileUtils.mv(source_dir + filename, dest_dir + sub_dir)
      end
      log(:debug, "Moved #{filename} to #{dest_dir + sub_dir}")
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
      log(:debug, "#{filename.green}")
      log(:debug, "#{'DateTimeOriginal:'.ljust(30)} #{exif['DateTimeOriginal']}")
      log(:debug, "#{'FileModifyDate:'.ljust(30)} #{exif['FileModifyDate']}")
      event_time = exif['DateTimeOriginal']
    elsif filename.downcase.end_with?('mov')
      exif = MiniExiftool.new(file_path)
      log(:debug, "#{filename.green}")
      log(:debug, "#{'ContentCreateDate:'.ljust(30)} #{exif['ContentCreateDate']}")
      log(:debug, "#{'CreateDate:'.ljust(30)} #{exif['CreateDate']}")
      log(:debug, "#{'FileModifyDate:'.ljust(30)} #{exif['FileModifyDate']}")
      event_time = exif['ContentCreateDate'] ? exif['ContentCreateDate'] : exif['CreateDate']
    else
      log(:debug, "#{filename.green} #{'UNRECOGNIZED FILE TYPE'.red}")
    end
    event_time
  end

  def log(level, message)
    logger.send(level, "#{options[:test_mode] ? '[TEST MODE] '.magenta : ''}#{message}")
  end

  def logger
    return @logger if @logger
    @logger = Logging.logger[self]
  end

  def init_logger
    Logging.logger.root.level = options[:log_level].to_sym
    Logging.logger.root.add_appenders([appender_stdout, appender_file].compact)
  end

  def appender_stdout
    Logging.appenders.stdout('stdout', layout: layout)
  end

  def appender_file
    return nil unless options[:log_file]
    Logging.appenders.rolling_file(
      'rolling_file',
      filename: options[:log_file],
      layout: layout,
      age: 'daily',
      roll_by: 'date'
    )
  end

  def layout
    Logging.layouts.pattern.new(pattern: '[%d] %l - %m\n')
  end
end
