# typed: true
# frozen_string_literal: true

module Mochitype
  class Railtie < Rails::Railtie
    extend T::Sig

    # NOTE: (overload119) Temporarily removed so that the developer can choose to invoke the thread.
    # This gives more flexibility during adoption.
    #
    # Start the file watcher after all initializers have run
    # This ensures the user's configuration in config/initializers/mochitype.rb has been loaded
    initializer 'mochitype.start_watcher', after: :load_config_initializers do
      if Rails.env.development?
        Rails.application.config.after_initialize do
          # Mochitype.start_watcher!
        end
      end
    end

    rake_tasks do
      load 'tasks/mochitype.rake'
    end
  end
end
