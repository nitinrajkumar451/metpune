FactoryBot.define do
  factory :hackathon_insight do
    content { "# Hackathon Trends Analysis\n\nThis is test content for hackathon insights." }
    status { "pending" }

    trait :processing do
      status { "processing" }
    end

    trait :success do
      status { "success" }
    end

    trait :failed do
      status { "failed" }
      content { "Error: No successful team summaries found" }
    end
  end
end
