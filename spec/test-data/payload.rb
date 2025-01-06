# typed: true
# frozen_string_literal: true

# More advanced example with nested types.
class Payload < T::Struct
  extend T::Sig

  class Result < T::Struct
    class ResultType < T::Enum
      enums do
        ANIMAL = new
        PLANT = new
        HUMAN = new
      end
    end

    const :id, T.any(String, Integer)
    const :name, T.nilable(String)
    const :result_type, ResultType
  end

  const :results, T::Array[Result]
  const :is_success, T::Boolean

  # This is an example of a method that should not affect the output.
  sig { returns(T::Boolean) }
  def is_success?
    is_success
  end
end
