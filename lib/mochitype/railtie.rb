# typed: true
# frozen_string_literal: true

module Mochitype
  class Railtie < Rails::Railtie
    extend T::Sig

    # Start the file watcher after all initializers have run
    # This ensures the user's configuration in config/initializers/mochitype.rb has been loaded
    initializer 'mochitype.start_watcher', after: :load_config_initializers do
      # Only start in development mode
      if Rails.env.development?
        # The watcher will be started after the configuration block runs
        # We use an after_initialize hook to ensure all configuration is loaded
        Rails.application.config.after_initialize do
          Mochitype.start_watcher!
        end
      end
    end
  end
end
