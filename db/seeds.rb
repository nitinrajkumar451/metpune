# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default judging criteria
judging_criteria = [
  {
    name: "Innovation",
    description: "How innovative is the solution? Does it present new ideas or approaches?",
    weight: 3.0
  },
  {
    name: "Technical Execution",
    description: "How well is the project implemented technically? Is the code well-structured?",
    weight: 4.0
  },
  {
    name: "Impact",
    description: "What is the potential impact of this solution? Does it solve a significant problem?",
    weight: 4.5
  },
  {
    name: "Presentation Quality",
    description: "How clear and effective is the presentation of the project? Is it easy to understand?",
    weight: 2.5
  },
  {
    name: "Completeness",
    description: "How complete is the project? Are all features implemented as described?",
    weight: 3.5
  }
]

judging_criteria.each do |criteria|
  JudgingCriterion.find_or_create_by!(name: criteria[:name]) do |criterion|
    criterion.description = criteria[:description]
    criterion.weight = criteria[:weight]
  end
end

puts "Created #{JudgingCriterion.count} judging criteria"
