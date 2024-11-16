module Mochitype
  class Railtie < Rails::Railtie
    config.after_initialize do
      puts "starting filewatcher"
      Mochitype::FileWatcher.start
    end
  end
end
