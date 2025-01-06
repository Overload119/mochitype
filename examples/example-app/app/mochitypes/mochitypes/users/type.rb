# frozen_string_literal: true
# typed: strict

module Mochitypes
  module Users
    class Type < T::Enum
      enums do
        BASIC = new
        ADVANCED = new
      end
    end
  end
end
