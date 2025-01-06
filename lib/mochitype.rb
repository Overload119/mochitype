# Core dependencies
require 'rails'
require 'listen'
require 'prism'
require 'sorbet-runtime'

require 'mochitype/version'
require 'mochitype/configuration'
require 'mochitype/ruby_type_utils'

require 'mochitype/convertible_property'
require 'mochitype/convertible_class'
require 'mochitype/type_converter'
require 'mochitype/reflection_type_converter'
require 'mochitype/ast_type_converter'

require 'mochitype/file_watcher'
require 'mochitype/railtie' if defined?(Rails)

module Mochitype
  class Error < StandardError
  end

  module ViewHelper
    def mochitype_render(*args, **kwargs)
      # Your custom rendering logic will go here
      # This method will be available in all Rails views
      'Placeholder for custom rendering logic'
    end
  end
end
