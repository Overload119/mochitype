# Core dependencies
require "rails"
require "listen"
require "prism"
require "sorbet-runtime"

require "mochitype/version"
require "mochitype/configuration"
require "mochitype/type_converter"
require "mochitype/file_watcher"
require "mochitype/railtie" if defined?(Rails)

module Mochitype
  class Error < StandardError
  end

  module ViewHelper
    def mochitype_render(*args, **kwargs)
      # Your custom rendering logic will go here
      # This method will be available in all Rails views
      "Placeholder for custom rendering logic"
    end
  end
end
