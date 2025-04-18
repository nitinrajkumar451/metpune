FactoryBot.define do
  factory :team_evaluation do
    sequence(:team_name) { |n| "Team#{n}" }
    scores do
      {
        "Innovation" => { "score" => 4.2, "weight" => 3.0, "feedback" => "Great innovative ideas" },
        "Technical Execution" => { "score" => 3.8, "weight" => 4.0, "feedback" => "Solid technical implementation" },
        "Impact" => { "score" => 4.5, "weight" => 4.5, "feedback" => "Significant potential impact" }
      }
    end
    total_score { 4.18 } # This will be auto-calculated, but we set it for testing
    comments { "Overall this is a strong project with great potential." }
    status { "success" }

    # For pending and processing states, we still need to provide scores to pass validation
    # In the real app, these would be created with scores={} and then updated
    trait :pending do
      scores do
        {
          "Placeholder" => { "score" => 0, "weight" => 1.0, "feedback" => "Pending evaluation" }
        }
      end
      total_score { nil }
      comments { nil }
      status { "pending" }
    end

    trait :processing do
      scores do
        {
          "Placeholder" => { "score" => 0, "weight" => 1.0, "feedback" => "Processing evaluation" }
        }
      end
      total_score { nil }
      comments { nil }
      status { "processing" }
    end

    trait :failed do
      scores do
        {
          "Placeholder" => { "score" => 0, "weight" => 1.0, "feedback" => "Failed evaluation" }
        }
      end
      total_score { nil }
      comments { "Error processing evaluation." }
      status { "failed" }
    end

    trait :high_score do
      scores do
        {
          "Innovation" => { "score" => 4.8, "weight" => 3.0, "feedback" => "Exceptionally innovative" },
          "Technical Execution" => { "score" => 4.9, "weight" => 4.0, "feedback" => "Outstanding technical implementation" },
          "Impact" => { "score" => 5.0, "weight" => 4.5, "feedback" => "Transformative potential impact" }
        }
      end
      total_score { 4.91 }
      comments { "Outstanding across all dimensions. A top-tier project." }
    end

    trait :low_score do
      scores do
        {
          "Innovation" => { "score" => 2.1, "weight" => 3.0, "feedback" => "Limited innovation shown" },
          "Technical Execution" => { "score" => 2.5, "weight" => 4.0, "feedback" => "Basic implementation with issues" },
          "Impact" => { "score" => 3.0, "weight" => 4.5, "feedback" => "Moderate potential impact" }
        }
      end
      total_score { 2.59 }
      comments { "Shows promise but needs significant improvement in several areas." }
    end
  end
end
