# typed: true
# frozen_string_literal: true

# Test multiple enums and complex unions
class OrderStatus < T::Enum
  enums do
    PENDING = new
    PROCESSING = new
    SHIPPED = new
    DELIVERED = new
    CANCELLED = new
  end
end

class OrderResponse < T::Struct
  class Priority < T::Enum
    enums do
      LOW = new
      MEDIUM = new
      HIGH = new
      URGENT = new
    end
  end

  const :id, String
  const :status, OrderStatus
  const :priority, Priority
  const :amount, Float
  const :metadata, T::Hash[String, String]
end
