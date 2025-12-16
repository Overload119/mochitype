# typed: true
# frozen_string_literal: true

module Mochitype
  # Recursively serializes T::Struct and T::Enum objects to hashes.
  # Unlike Sorbet's default serialize, this always includes nil keys
  # instead of omitting them, ensuring consistent JSON output for frontend types.
  module RecursiveSerializer
    extend T::Sig

    sig { params(value: T.untyped).returns(T.untyped) }
    def self.serialize_value(value)
      case value
      when T::Struct
        serialize_struct(value)
      when T::Enum
        value.serialize
      when Array
        value.map { |v| serialize_value(v) }
      when Hash
        value.transform_values { |v| serialize_value(v) }
      else
        value
      end
    end

    sig { params(obj: T::Struct).returns(T::Hash[String, T.untyped]) }
    def self.serialize_struct(obj)
      obj.class.props.keys.each_with_object({}) do |prop_name, h|
        h[prop_name.to_s] = serialize_value(obj.public_send(prop_name))
      end
    end
  end
end
