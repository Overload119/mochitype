# typed: true
# frozen_string_literal: true

puts "load #{__FILE__}"

# Simple example of a struct.
module Mochitypes
  class App < T::Struct
    const :string_vaue, T.nilable(String)
    const :integer_value, T.nilable(Integer)
    const :boolean_value, T.nilable(T::Boolean)
    const :array_value, T.nilable(T::Array[T.untyped])

    const :hash_value, T.nilable(T::Hash[String, T.untyped])
  end
end
