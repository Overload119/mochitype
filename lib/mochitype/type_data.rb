# typed: strict
# frozen_string_literal: true

module Mochitype
  class ConvertibleStruct < T::Struct
    extend T::Sig

    const :name, String
    const :props, T::Hash[String, String]
    const :type, T.nilable(String)

    sig { returns(String) }
    def typescript_name
      "#{name}Schema"
    end
  end
end
