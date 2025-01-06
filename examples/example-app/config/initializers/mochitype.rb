Rails.application.config.after_initialize do
  Mochitype.configure do |config|
    config.watch_path = 'app/mochitypes/mochitypes'
    config.output_path = 'app/assets/javascript/__generated__/mochitypes'
  end
  Mochitype::FileWatcher.start
end
