require 'logger_util'

types_dir = File.join(File.dirname(__FILE__), 'types/*.rb')
Dir[types_dir].each { |file| require file }

#
# Types module with a factory method for creating media type handlers
#
module Types
  include LoggerUtil

  def self.type_handler(source_dir, filename, options)
    type_class = File.extname(filename)[1..-1].upcase
    const_get("Types::#{type_class}").new(source_dir, filename, options)
  rescue NameError
    nil
  end
end
