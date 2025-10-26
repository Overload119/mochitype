# typed: true
# frozen_string_literal: true

# Test deeply nested structures
class Organization < T::Struct
  class Department < T::Struct
    class Team < T::Struct
      class Member < T::Struct
        const :id, Integer
        const :name, String
        const :role, String
      end

      const :team_name, String
      const :members, T::Array[Member]
    end

    const :dept_name, String
    const :teams, T::Array[Team]
  end

  const :org_name, String
  const :departments, T::Array[Department]
  const :employee_count, Integer
end
