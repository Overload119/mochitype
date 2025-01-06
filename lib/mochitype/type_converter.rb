# typed: true
# frozen_string_literal: true

require_relative 'reflection_type_converter.rb'

module Mochitype
  class TypeConverter < ReflectionTypeConverter
    class << self
      extend T::Sig

      sig { params(file_path: String).returns(T.nilable(String)) }
      def convert_file(file_path)
        output_file = determine_output_path(file_path)
        FileUtils.mkdir_p(File.dirname(output_file))
        File.write(output_file, new(file_path).build_typescript_file)
        output_file
      end

      sig { params(file_path: String).returns(String) }
      def determine_output_path(file_path)
        base_path =
          if Rails.root
            Rails.root.join(Mochitype.configuration.output_path)
          else
            Mochitype.configuration.output_path
          end

        relative_path = file_path.sub(/.*#{Mochitype.configuration.watch_path}/, '')
        File.join(base_path, relative_path.sub('.rb', '.ts'))
      end
    end
  end
end
