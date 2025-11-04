# typed: true
# frozen_string_literal: true

namespace :mochitype do
  desc 'Generate TypeScript types from Ruby Sorbet definitions'
  task generate: :environment do
    require 'mochitype'

    watch_path = Mochitype.configuration.watch_path
    output_path = Mochitype.configuration.output_path

    puts "Mochitype: Scanning #{watch_path} for Ruby type definitions..."

    # Find all .rb files in watch_path
    files = Dir.glob(File.join(watch_path, '**', '*.rb'))

    if files.empty?
      puts "No Ruby files found in #{watch_path}"
      next
    end

    converted_count = 0
    files.each do |file_path|
      output_file = Mochitype::TypeConverter.convert_file(file_path)
      if output_file
        puts "Generated #{output_file}"
        converted_count += 1
      end
    end

    puts "Successfully generated #{converted_count} TypeScript file(s) in #{output_path}"
  end
end
