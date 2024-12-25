# frozen_string_literal: true
# typed: strict

module Mochitypes
  module Users
    class Show < T::Struct
      class UserShowDetails < T::Struct
        const :username, T.nilable(String)
        const :id, Integer
        const :created_at, DateTime
      end

      const :details, T.nilable(UserShowDetails)
      const :other_user_details, T::Array[UserShowDetails]
    end
  end
end
