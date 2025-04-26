criteria_signature = "AI through out the SDLC:25|Innovation:12|Knowledge sharing:12|Speed and efficiency:25|craft and quality:12|working product:14"
hackathon_id = 5

# Get the base query
base_query = Hackathon.find(hackathon_id).team_evaluations
puts "Base query: Found #{base_query.count} total evaluations for hackathon #{hackathon_id}"

# Filter by criteria signature
filtered_query = base_query.where("comments LIKE ?", "%#{criteria_signature}%")
puts "Filtered query: Found #{filtered_query.count} evaluations matching criteria signature"

# Get all successful evaluations sorted by score
success_evals = filtered_query.success.ordered_by_score
puts "Success evaluations: Found #{success_evals.count} success evaluations"

# Format the leaderboard data
leaderboard = success_evals.map do |evaluation|
  {
    team_name: evaluation.team_name,
    total_score: evaluation.total_score,
    scores: evaluation.scores
  }
end

# Add rankings (handling ties correctly)
current_rank = 1
current_score = nil

leaderboard.each_with_index do |entry, index|
  if current_score != entry[:total_score]
    current_rank = index + 1
    current_score = entry[:total_score]
  end

  entry[:rank] = current_rank
end

puts "\nLeaderboard:"
leaderboard.each do |entry|
  puts "#{entry[:rank]}. #{entry[:team_name]} - Score: #{entry[:total_score]}"
end