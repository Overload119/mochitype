# typed: true
# frozen_string_literal: true

module Mochitype
  class ConvertibleProperty < T::Struct
    const :zod_definition, String
    const :discovered_classes, T::Array[Class], default: []
  end
end
