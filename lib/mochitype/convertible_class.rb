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

  # The name of the TypeScript type alias
  sig { returns(String) }
  def typescript_type_name
    js_name = klass.to_s.gsub('::', '')
    # For very short class names (3 chars or less), use just the class name
    # Otherwise, use T prefix + the typescript_name
    if js_name.length <= 3
      js_name
    else
      "T#{typescript_name}"
    end
  end
end
