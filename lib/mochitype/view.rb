# typed: true
# frozen_string_literal: true

module Mochitype
  module View
    extend T::Sig

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
