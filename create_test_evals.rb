criteria_signature = "AI through out the SDLC:25|Innovation:12|Knowledge sharing:12|Speed and efficiency:25|craft and quality:12|working product:14"
hackathon = Hackathon.find(5)

[ "TeamAlpha", "TeamBeta", "TeamDelta", "TeamGamma", "TeamOmega" ].each do |team_name|
  puts "Creating test evaluation for #{team_name}"

  # Generate random scores
  scores = {}

  # Use the actual criteria from the database
  JudgingCriterion.where(hackathon_id: hackathon.id).each do |criterion|
    # Random score between 3.5 and 4.8
    score = (3.5 + rand * 1.3).round(1)

    scores[criterion.name] = {
      "score" => score,
      "weight" => criterion.weight,
      "feedback" => "Team #{team_name} performed well on this criterion."
    }
  end

  # Calculate total score
  total_weighted_score = 0
  total_weight = 0

  scores.each do |_, data|
    total_weighted_score += data["score"] * data["weight"].to_f
    total_weight += data["weight"].to_f
  end

  average_score = (total_weighted_score / [ total_weight, 0.01 ].max).round(2)

  # Create or update the evaluation
  evaluation = TeamEvaluation.find_or_initialize_by(team_name: team_name, hackathon_id: hackathon.id)
  evaluation.update!(
    scores: scores,
    total_score: average_score,
    comments: "Evaluated using criteria set: #{criteria_signature}",
    status: "success"
  )

  puts "Created/updated evaluation with total score: #{average_score}"
end

puts "Done!"
