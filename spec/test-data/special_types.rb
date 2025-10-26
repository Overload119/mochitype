# typed: true
# frozen_string_literal: true

# Test special Sorbet types that should map to z.unknown()
class SpecialTypes < T::Struct
  # T.untyped - completely untyped value
  const :untyped_field, T.untyped
  
  # T.any - union of multiple types (when used with more than 2 types)
  const :any_field, T.any(String, Integer, Float, Symbol)
  
  # T.all - intersection type (rare but possible)
  const :all_field, T.all(T::Struct, Kernel)
  
  # T.class_of - reference to a class itself (not an instance)
  const :class_of_field, T.class_of(String)
  
  # T.attached_class - used in module mixins
  const :attached_field, T.attached_class
  
  # Regular field for comparison
  const :normal_field, String
end
