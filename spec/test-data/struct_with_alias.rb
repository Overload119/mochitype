# typed: true
# frozen_string_literal: true

# More advanced example with nested types.
class StructWithAlias < T::Struct
  extend T::Sig
  StringKeyHash = T.type_alias { T::Hash[String, T.untyped] }

  const :string_key_hash, StringKeyHash
  const :string_key_array, T::Array[String]
  const :string_key_hash_array, T::Array[StringKeyHash]
end
