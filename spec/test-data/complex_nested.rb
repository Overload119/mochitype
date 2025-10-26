# typed: true
# frozen_string_literal: true

# Complex nested structure with multiple levels
module Api
  module V1
    class ComplexNested < T::Struct
      class Address < T::Struct
        const :street, String
        const :city, String
        const :zip_code, String
        const :country, String
      end

      class ContactInfo < T::Struct
        const :email, String
        const :phone, T.nilable(String)
        const :address, Address
      end

      class UserStatus < T::Enum
        enums do
          ACTIVE = new
          INACTIVE = new
          SUSPENDED = new
          PENDING = new
        end
      end

      class Metadata < T::Struct
        const :tags, T::Array[String]
        const :scores, T::Hash[String, Float]
        const :created_at, String
        const :updated_at, T.nilable(String)
      end

      const :id, Integer
      const :name, String
      const :status, UserStatus
      const :contact_info, ContactInfo
      const :metadata, Metadata
      const :roles, T::Array[String]
      const :is_verified, T::Boolean
    end
  end
end
