FactoryBot.define do
  factory :team_summary do
    sequence(:team_name) { |n| "Team#{n}" }
    content { "# Team Report\n\n## PRODUCT OBJECTIVE\nThis is a sample team summary report." }
    status { "success" }

    trait :pending do
      status { "pending" }
      content { nil }
    end

    trait :processing do
      status { "processing" }
      content { nil }
    end

    trait :failed do
      status { "failed" }
      content { "Error: Failed to generate team summary" }
    end
  end
end
