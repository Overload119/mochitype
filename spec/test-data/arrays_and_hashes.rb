# typed: true
# frozen_string_literal: true

# Example with arrays and hashes
class ArraysAndHashes < T::Struct
  const :simple_array, T::Array[String]
  const :number_array, T::Array[Integer]
  const :nested_array, T::Array[T::Array[String]]
  const :string_hash, T::Hash[String, String]
  const :mixed_hash, T::Hash[String, Integer]
  const :array_of_hashes, T::Array[T::Hash[String, String]]
  const :complex_hash, T::Hash[String, T::Array[Integer]]
end
