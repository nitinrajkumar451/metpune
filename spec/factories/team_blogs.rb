FactoryBot.define do
  factory :team_blog do
    sequence(:team_name) { |n| "BlogTeam#{n}" }
    content { "# Sample Blog Post\n\nThis is a sample blog post for testing purposes." }
    status { "success" }

    trait :pending do
      content { nil }
      status { "pending" }
    end

    trait :processing do
      content { nil }
      status { "processing" }
    end

    trait :failed do
      content { "Error generating blog." }
      status { "failed" }
    end
  end
end
