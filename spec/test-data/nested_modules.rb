# typed: true
# frozen_string_literal: true

# Test deeply nested modules and classes
module Api
  module V1
    module Responses
      class UserProfile < T::Struct
        const :id, Integer
        const :username, String
        const :email, String
        const :verified, T::Boolean
      end
    end
  end
end
