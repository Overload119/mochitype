require 'listen'
require 'pry'

module Mochitype
  class FileWatcher
    def self.start
      puts "starting filewatcher 2"
      return unless Rails.env.development?

      path = Rails.root.join(Mochitype.configuration.watch_path)
      FileUtils.mkdir_p(path) unless File.directory?(path)



      Dir.glob("#{path}/**/*.rb").each do |file|
        begin
          binding.pry
          TypeConverter.convert_file(file)
          Rails.logger.info "Mochitype: Successfully converted #{file} to TypeScript"
        rescue => e
          Rails.logger.error "Mochitype: Error converting #{file}: #{e.message}"
        end
      end

      listener = Listen.to(path, only: /\.rb$/) do |modified, added, removed|
        (modified + added).each do |file|
          begin
            TypeConverter.convert_file(file)
            Rails.logger.info "Mochitype: Successfully converted #{file} to TypeScript"
          rescue => e
            Rails.logger.error "Mochitype: Error converting #{file}: #{e.message}"
          end
        end

        removed.each do |file|
          begin
            ts_file = TypeConverter.determine_output_path(file)
            File.delete(ts_file) if File.exist?(ts_file)
            Rails.logger.info "Mochitype: Removed TypeScript file for #{file}"
          rescue => e
            Rails.logger.error "Mochitype: Error removing TypeScript file for #{file}: #{e.message}"
          end
        end
      end

      listener.start
      Rails.logger.info "Mochitype: Watching for Sorbet struct changes in #{path}"
    end
  end
end
