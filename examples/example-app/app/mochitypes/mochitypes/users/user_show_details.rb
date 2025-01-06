# frozen_string_literal: true
# typed: strict

module Mochitypes
  module Users
    class UserShowDetails < T::Struct
      const :username, T.nilable(String)
      const :id, Integer
      const :created_at, DateTime
      const :type, Type
    end
  end
end
