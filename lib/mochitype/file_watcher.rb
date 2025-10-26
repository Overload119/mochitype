# typed: true
# frozen_string_literal: true

module Mochitype
  class FileWatcher
    class << self
      extend T::Sig

      attr_reader :listener, :mutex

      # Logger that works with or without Rails
      sig { returns(T.untyped) }
      def logger
        defined?(Rails) && Rails.logger ? Rails.logger : Logger.new($stdout)
      end

      # Performs a full sweep of the watched Ruby type directory and the generated TypeScript output directory.
      #
      # - For every Ruby file under the configured `watch_path`, determines the expected TypeScript output path.
      # - Deletes any orphaned TypeScript files in the output directory that do not have a corresponding Ruby source file.
      # - Generates TypeScript files for any Ruby files that are missing outputs.
      #
      # This method is typically called on Rails boot in development to ensure the generated TypeScript
      # is in sync with the Ruby source files, and to clean up any stale outputs.
      #
      # Logs actions and errors using Rails.logger (or stdout in headless mode).
      sig { void }
      def sweep
        begin
          ts_base = Mochitype.configuration.output_path

          # Build expected TS paths from all Ruby files.
          ruby_files = Dir.glob("#{Mochitype.configuration.watch_path}/**/*.rb")
          expected_ts = {}
          ruby_files.each do |rb_file|
            ts_path = TypeConverter.determine_output_path(rb_file)
            expected_ts[ts_path] = rb_file
          end

          # Delete orphan TS files (those without a corresponding Ruby file).
          Dir
            .glob("#{ts_base}/**/*.ts")
            .each do |ts_file|
              begin
                next if expected_ts.key?(ts_file)
                File.delete(ts_file)
                logger.info "Mochitype: Removed orphan TypeScript file #{ts_file}"
              rescue => e
                logger.error "Mochitype: Error removing orphan TypeScript file #{ts_file}: #{e.message}"
              end
            end

          # Generate missing TS files for Ruby files without outputs.
          ruby_files.each do |rb_file|
            begin
              ts_path = TypeConverter.determine_output_path(rb_file)
              next if File.exist?(ts_path)
              TypeConverter.convert_file(rb_file)
              logger.info "Mochitype: Generated missing TypeScript for #{rb_file}"
            rescue => e
              logger.error "Mochitype: Error generating TypeScript for #{rb_file}: #{e.message}"
            end
          end
        rescue => e
          logger.error "Mochitype: Initial sweep failed: #{e.message}"
        end
      end

      sig { void }
      def start
        return unless Rails.env.development?
        return if @listener # Already started

        @mutex = Mutex.new

        path =
          (
            if Rails.root
              Rails.root.join(Mochitype.configuration.watch_path)
            else
              Mochitype.configuration.watch_path
            end
          )
        FileUtils.mkdir_p(path) unless File.directory?(path)

        # Initial conversion of all existing files
        @mutex.synchronize do
          Dir
            .glob("#{path}/**/*.rb")
            .each do |file|
              begin
                TypeConverter.convert_file(file)
                logger.info "Mochitype: Successfully converted #{file} to TypeScript"
              rescue StandardError => e
                logger.error "Mochitype: Error converting #{file}"
                logger.error "  #{e.class}: #{e.message}"
                logger.error "  #{e.backtrace.first(3).join("\n  ")}" if e.backtrace
              end
            end
        end

        @listener =
          Listen.to(path, only: /\.rb$/) do |modified, added, removed|
            @mutex.synchronize do
              handle_file_changes(modified, added, removed)
            end
          end

        @listener.start
        Kernel.puts "Mochitype starting: Watching for Sorbet struct changes in #{path}"
        Kernel.puts "* #{Dir.glob("#{path}/**/*.rb").count} file(s) in #{path}"
        Kernel.puts "* #{Dir.glob("#{Mochitype.configuration.output_path}/**/*.ts").count} generated TS file(s) in #{Mochitype.configuration.output_path}"

        # Run sweep synchronously after initial conversion
        @mutex.synchronize { sweep }
      end

      sig { params(modified: T::Array[String], added: T::Array[String], removed: T::Array[String]).void }
      def handle_file_changes(modified, added, removed)
        (modified + added).each do |file|
          begin
            TypeConverter.convert_file(file)
            logger.info "Mochitype: Successfully converted #{file} to TypeScript"
          rescue StandardError => e
            logger.error "Mochitype: Error converting #{file}"
            logger.error "  #{e.class}: #{e.message}"
            logger.error "  #{e.backtrace.first(3).join("\n  ")}" if e.backtrace
          end
        end

        removed.each do |file|
          begin
            ts_file = TypeConverter.determine_output_path(file)
            File.delete(ts_file) if File.exist?(ts_file)
            logger.info "Mochitype: Removed TypeScript file for #{file}"
          rescue StandardError => e
            logger.error "Mochitype: Error removing TypeScript file for #{file}"
            logger.error "  #{e.class}: #{e.message}"
          end
        end
      end
    end
  end
end
