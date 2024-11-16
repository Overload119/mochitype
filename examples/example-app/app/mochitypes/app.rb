# frozen_string_literal: true
# typed: true

class App < T::Struct
  const :string_vaue, T.nilable(String)
  const :integer_value, T.nilable(Integer)
  const :boolean_value, T.nilable(T::Boolean)
  const :array_value, T.nilable(T::Array[T.untyped])
  const :hash_value, T.nilable(T::Hash[String, T.untyped])
end
