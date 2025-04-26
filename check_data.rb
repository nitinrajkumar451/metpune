#!/usr/bin/env ruby
require_relative 'config/environment'

# Check the counts of all data
puts "Submissions: #{Submission.count}"
puts "Team Summaries: #{TeamSummary.count}"
puts "Team Evaluations: #{TeamEvaluation.count}"
puts "Team Blogs: #{TeamBlog.count}"
puts "Hackathon Insights: #{HackathonInsight.count}"

puts "\nTeam Blog Titles:"
TeamBlog.all.each do |blog|
  title = blog.content.match(/title: "([^"]+)"/)&.captures&.first || "No title found"
  puts "- #{blog.team_name}: #{title} (Status: #{blog.status})"
end