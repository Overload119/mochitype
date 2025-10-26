# typed: true
# frozen_string_literal: true

# Example with various union types
class UnionTypes < T::Struct
  const :string_or_number, T.any(String, Integer)
  const :multiple_types, T.any(String, Integer, Float)
  const :boolean_value, T::Boolean
  const :nullable_string, T.nilable(String)
  const :nullable_number, T.nilable(Integer)
  const :array_of_strings_or_numbers, T::Array[T.any(String, Integer)]
end
