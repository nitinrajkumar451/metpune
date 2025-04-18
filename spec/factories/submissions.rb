FactoryBot.define do
  factory :submission do
    team_name { Faker::Team.name }
    filename { Faker::File.file_name }
    file_type { 'pdf' } # Default file type
    sequence(:source_url) { |n| "https://drive.google.com/file/d/#{n}" }
    raw_text { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    status { 'pending' }

    trait :pdf do
      file_type { 'pdf' }
      filename { Faker::File.file_name(ext: 'pdf') }
    end

    trait :docx do
      file_type { 'docx' }
      filename { Faker::File.file_name(ext: 'docx') }
    end

    trait :pptx do
      file_type { 'pptx' }
      filename { Faker::File.file_name(ext: 'pptx') }
    end

    trait :jpg do
      file_type { 'jpg' }
      filename { Faker::File.file_name(ext: 'jpg') }
    end

    trait :png do
      file_type { 'png' }
      filename { Faker::File.file_name(ext: 'png') }
    end

    trait :zip do
      file_type { 'zip' }
      filename { Faker::File.file_name(ext: 'zip') }
    end

    trait :pending do
      status { 'pending' }
    end

    trait :processing do
      status { 'processing' }
    end

    trait :success do
      status { 'success' }
    end

    trait :failed do
      status { 'failed' }
    end
  end
end
