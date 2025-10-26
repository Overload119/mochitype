# typed: true
# frozen_string_literal: true

# Simple enum example
class SimpleEnum < T::Enum
  enums do
    RED = new
    GREEN = new
    BLUE = new
  end
end
