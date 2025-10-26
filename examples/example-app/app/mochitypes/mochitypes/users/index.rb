# frozen_string_literal: true
# typed: strict

module Mochitypes
  module Users
    # Example response using Mochitype::View for rendering
    class Index < T::Struct
      extend T::Sig
      include Mochitype::View

      class UserSummary < T::Struct
        const :id, Integer
        const :username, String
        const :email, String
        const :active, T::Boolean
      end

      const :users, T::Array[UserSummary]
      const :total_count, Integer
      const :page, Integer

      sig { params(page: Integer).returns(Index) }
      def self.from_data(page:)
        # In a real app, you'd fetch from the database
        new(
          users: [
            UserSummary.new(
              id: 1,
              username: 'alice',
              email: 'alice@example.com',
              active: true
            ),
            UserSummary.new(
              id: 2,
              username: 'bob',
              email: 'bob@example.com',
              active: true
            ),
          ],
          total_count: 2,
          page: page
        )
      end
    end
  end
end
