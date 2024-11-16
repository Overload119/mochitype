# frozen_string_literal: true
# typed: strict
require 'sorbet-runtime'

class UserShow < T::Struct

  class UserShowDetails < T::Struct
    const :username, T.nilable(String)
    const :id, Integer
    const :created_at, DateTime
  end

  const :details, T.nilable(UserShowDetails)
  const :other_users, T::Array[UserShowDetails]
end

class UserShowResponse < T::Struct
  const :id, Integer
  const :name, String
  const :email, T.nilable(String)
  const :roles, T::Array[String]
  const :settings, T::Hash[String, T.any(String, Integer)]
  const :status, T::Enum['active', 'inactive', 'pending']
  const :is_admin, T::Boolean
end
