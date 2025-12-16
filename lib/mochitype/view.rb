# typed: true
# frozen_string_literal: true

module Mochitype
  module View
    extend T::Sig

    # Overrides T::Struct#serialize to always include nil keys in the output.
    # This ensures consistent JSON structure for frontend type safety with Zod schemas.
    sig { returns(T::Hash[String, T.untyped]) }
    def serialize
      Mochitype::RecursiveSerializer.serialize_struct(self)
    end

    sig { params(view_context: ActionView::Base).returns(String) }
    def render_in(view_context)
      serialize.to_json
    end

    sig { returns(Symbol) }
    def format
      :json
    end
  end
end
