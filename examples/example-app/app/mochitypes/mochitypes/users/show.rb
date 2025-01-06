# frozen_string_literal: true
# typed: strict

module Mochitypes
  module Users
    class Show < T::Struct
      extend T::Sig

      const :details, T.nilable(UserShowDetails)
      const :other_user_details, T::Array[UserShowDetails]

      sig { returns(T::Hash[String, T.untyped]) }
      def self.render
        new(
          details:
            UserShowDetails.new(
              username: 'test',
              id: 1,
              created_at: DateTime.now,
              type: Type::ADVANCED,
            ),
          other_user_details: [
            UserShowDetails.new(
              username: 'test',
              id: 1,
              created_at: DateTime.now,
              type: Type::ADVANCED,
            ),
          ],
        ).serialize
      end
    end
  end
end
