require 'colorize'
require 'mini_exiftool'
require 'thor'
require 'yaml'

#
# Media Maid CLI
#
class MediaMaidCLI < Thor
  IGNORE_LIST = %w(. .. .DS_Store .picasa.ini)
  DIFF_THRESHOLD_IN_MILLIS = 1000;

  # input_source_dir_path = '/Users/jamie/Dropbox/Photos/Camera Sync/Test/'

  # # copy source files to /tmp
  # tmp_dest = '/tmp/media-maid/dest/'
  # tmp_source = '/tmp/media-maid/source/'
  # FileUtils.mkdir_p(tmp_source)
  # FileUtils.cp_r(Dir.glob(input_source_dir_path + '*.*'), tmp_source, :preserve => true)

  # source_dir_path = tmp_source
  # dest_dir_path = tmp_dest

  # # estimate(source_dir_path)
  # clean(source_dir_path, dest_dir_path)

  class_option :verbose, :type => :boolean

  desc 'fix_mtime', 'TODO'
  option :test, :type => :boolean
  def fix_mtime(source_dir)
    missing, not_needed, fixed = 0, 0, 0
    Dir.foreach(source_dir) do |file|
      next if IGNORE_LIST.include? file
      event_time = get_event_time(source_dir, file)
      if event_time
        mtime = File.mtime(source_dir + file)
        diff = (mtime - event_time).abs
        if diff > DIFF_THRESHOLD_IN_MILLIS
          update_mtime(source_dir + file, event_time)
          fixed += 1
        else
          log "event_time and mtime for #{file} are equal: #{event_time} - #{'NO FIX NEEDED'.blue}" if options[:verbose]
          not_needed += 1
        end
      else
        missing += 1
      end
    end
    log "SUMMARY --> Fixed: #{fixed.to_s.green} Not Needed: #{not_needed.to_s.green} Missing: #{missing.to_s.green}"
  end

  private

  def get_event_time(source_dir, filename)
    file_path = source_dir + filename.downcase
    if filename.end_with?('jpg')
      exif = MiniExiftool.new(file_path)
      if options[:verbose]
        log "#{filename.green}"
        log "#{'SubSecDateTimeOriginal:'.ljust(30)} #{exif['SubSecDateTimeOriginal']}"
        log "#{'DateTimeOriginal:'.ljust(30)} #{exif['DateTimeOriginal']}"
        log "#{'FileModifyDate:'.ljust(30)} #{exif['FileModifyDate']}"
      end
      exif['SubSecDateTimeOriginal'] ? exif['SubSecDateTimeOriginal'] : exif['DateTimeOriginal']
    elsif filename.end_with?('mov')
      exif = MiniExiftool.new(file_path)
      if options[:verbose]
        log "#{filename.green}"
        log "#{'ContentCreateDate:'.ljust(30)} #{exif['ContentCreateDate']}"
        log "#{'CreateDate:'.ljust(30)} #{exif['CreateDate']}"
        log "#{'FileModifyDate:'.ljust(30)} #{exif['FileModifyDate']}"
      end
      exif['ContentCreateDate'] ? exif['ContentCreateDate'] : exif['CreateDate']
    else
      log "#{filename.green} #{'UNRECOGNIZED FILE TYPE'.red}"
      nil
    end
  end

  def update_mtime(file, event_time)
    # FileUtils.touch(file, :mtime => event_time) unless options[:test]
    log "Updated mtime for #{file} to #{event_time}" if options[:verbose]
  end

  def move_file(source_dir, dest_dir, filename, event_time)
    sub_dir = "#{event_time.year}/#{event_time.strftime("%Y-%m")}-#{event_time.strftime("%B").downcase}"
    FileUtils.mkdir_p(dest_dir + sub_dir)
    FileUtils.mv(source_dir + filename, dest_dir + sub_dir)
  end

  def clean(source_dir_path, dest_dir_path)
    Dir.foreach(source_dir_path) do |file|
      next if file == '.' or file == '..'
      event_time = get_event_time(source_dir_path, file)
      if event_time
        update_mtime(source_dir_path + file, event_time)
        move_file(source_dir_path, dest_dir_path, file, event_time)
      end
    end
  end

  def log(message)
    puts "#{options[:test] ? '[TEST MODE] '.magenta : ''}#{message}"
  end
end
