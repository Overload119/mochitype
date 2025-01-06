# typed: true
# frozen_string_literal: true

module Mochitype
  class TypescriptUtils
    class << self
      extend T::Sig

      def plain_ruby_class_to_typescript_type(node)
        case T.unsafe(node).name.to_s
        when 'String'
          'z.string()'
        when 'Integer', 'Numeric', 'Float'
          'z.number()'
        else
          "#{T.unsafe(node).name}Schema"
        end
      end

      def number_type?(class_name)
        %w[Integer Numeric Float].include?(class_name)
      end
    end
  end
end
