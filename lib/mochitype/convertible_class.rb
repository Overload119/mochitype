# typed: true
# frozen_string_literal: true

# Data container that contains all the properties that can be turned into a TypeScript file for a class.
# The class must either be a T::Enum or T::Struct
class ConvertibleClass < T::Struct
  extend T::Sig

  const :klass, Class
  prop :props, T::Hash[String, String], default: {}
  prop :inner_classes, T::Array[ConvertibleClass], default: []

  # The name of the type in the generated Typescript file.
  # This is the name of the Zod definition.
  sig { returns(String) }
  def typescript_name
    js_name = klass.to_s.gsub('::', '')
    klass < T::Enum ? "#{js_name}Enum" : "#{js_name}Schema"
  end
end
