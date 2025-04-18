FactoryBot.define do
  factory :judging_criterion do
    sequence(:name) { |n| "Criterion #{n}" }
    description { "Description of the judging criterion" }
    weight { rand(1.0..5.0).round(2) }

    trait :innovation do
      name { "Innovation" }
      description { "How innovative is the solution? Does it present new ideas or approaches?" }
      weight { 3.0 }
    end

    trait :technical_execution do
      name { "Technical Execution" }
      description { "How well is the project implemented technically? Is the code well-structured?" }
      weight { 4.0 }
    end

    trait :impact do
      name { "Impact" }
      description { "What is the potential impact of this solution? Does it solve a significant problem?" }
      weight { 4.5 }
    end

    trait :presentation do
      name { "Presentation Quality" }
      description { "How clear and effective is the presentation of the project? Is it easy to understand?" }
      weight { 2.5 }
    end

    trait :completeness do
      name { "Completeness" }
      description { "How complete is the project? Are all features implemented as described?" }
      weight { 3.5 }
    end
  end
end
