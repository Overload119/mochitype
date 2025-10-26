# Configure Mochitype paths
# The Railtie will automatically start the file watcher in development mode
Mochitype.configure do |config|
  config.watch_path = 'app/mochitypes/mochitypes'
  config.output_path = 'app/assets/javascript/__generated__/mochitypes'
end
