# typed: true
# frozen_string_literal: true

module Mochitype
  class RubyTypeUtils
    class << self
      extend T::Sig

      sig { params(statement_node: Prism::Node).returns(T::Boolean) }
      def struct_call_node?(statement_node)
        return false unless statement_node.is_a?(Prism::CallNode)
        receiver = statement_node.receiver
        receiver.is_a?(Prism::ConstantPathNode) && receiver.full_name == 'T::Struct'
      end

      sig { params(statement_node: Prism::Node).returns(T::Boolean) }
      def enum_call_node?(statement_node)
        return false unless statement_node.is_a?(Prism::CallNode)
        receiver = statement_node.receiver
        receiver.is_a?(Prism::ConstantPathNode) && receiver.full_name == 'T::Enum'
      end
    end
  end
end
