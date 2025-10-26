# typed: true
# frozen_string_literal: true

# Test complex union types
class SearchResult < T::Struct
  class Match < T::Struct
    const :score, Float
    const :highlight, String
  end

  # Union of different types
  const :result_id, T.any(String, Integer)
  const :title, String
  const :match_info, T.nilable(Match)
  const :tags, T::Array[String]
  const :category, T.any(String, Integer, Float)
end
