
#
# Helper mixin module for logging
#
module LoggerUtil
  def self.included(base)
    base.extend(ClassMethods)
  end

  # logger on dat class
  module ClassMethods
    def logger
      Logging.logger[is_a?(Class) ? self : name]
    end
  end

  def logger
    self.class.logger
  end

  def log_message(level, message, test_mode = false)
    logger.send(level, "#{test_mode ? '[TEST MODE] '.magenta : ''}#{message}")
  end
end
