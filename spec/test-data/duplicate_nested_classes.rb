# typed: true
# frozen_string_literal: true

require 'sorbet-runtime'

class UrlImageHash < T::Struct
  const :url, String
  const :width, Integer
  const :height, Integer
end

class ApplicationResearchArea < T::Struct
  const :id, Integer
  const :name, String
end

class UniversityInfo < T::Struct
  const :id, Integer
  const :name, String
  const :slug, String
  const :country_code, T.nilable(String)
  const :claimed, T::Boolean
  const :logo, UrlImageHash
  const :banner_video, UrlImageHash
  const :banner_image, UrlImageHash
  const :research_areas, T::Array[ApplicationResearchArea]
  const :more_research_areas, T::Array[ApplicationResearchArea]
end
