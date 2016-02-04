require 'colorize'
require 'logging'
require 'mini_exiftool'
require 'thor'

require 'logger_util'
require 'types'

#
# Media Maid CLI
#
class MediaMaidCLI < Thor
  include LoggerUtil

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
    fixed, noop, missing, unrecognized = 0, 0, 0, 0
    Dir.foreach(source_dir) do |filename|
      next if IGNORE_LIST.include?(filename)
      # get media handler
      media_handler = Types.type_handler(source_dir, filename, options)
      next unrecognized += 1 if media_handler.nil?
      # update mtime
      result = media_handler.update_mtime
      case result
      when 1
        fixed += 1
      when 0
        noop += 1
      when -1
        missing += 1
      end
    end
    log(:info, "SUMMARY --> \
      Fixed: #{fixed.to_s.green} \
      No-Op: #{noop.to_s.green} \
      Missing: #{missing.to_s.green} \
      Unrecognized: #{unrecognized.to_s.green}
    ")
  end

  desc 'organize SOURCE_DIR DEST_DIR', 'Organizes all media in the given SOURCE_DIR to the given DEST_DIR using a date-based directory structure'
  def organize(source_dir, dest_dir)
    moved, missing, unrecognized = 0, 0, 0
    Dir.foreach(source_dir) do |filename|
      next if IGNORE_LIST.include? filename
      # get media handler
      media_handler = Types.type_handler(source_dir, filename, options)
      next unrecognized += 1 if media_handler.nil?
      # move file
      result = media_handler.move_file(dest_dir)
      if result == 1
        moved += 1
      else
        missing += 1
      end
    end
    log(:info, "SUMMARY --> \
      Moved: #{moved.to_s.green} \
      Missing: #{missing.to_s.green} \
      Unrecognized: #{unrecognized.to_s.green}
    ")
  end

  private

  def log(level, message)
    log_message(level, message, options[:test_mode])
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
