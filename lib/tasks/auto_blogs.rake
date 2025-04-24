# This rake task is designed to automatically generate blogs, summaries, and evaluations
# for teams in the hackathon system. It can be run manually or scheduled.
#
# Usage:
#   rake auto_blogs:generate - Generate blogs for teams with summaries
#   rake auto_blogs:generate_all - Generate summaries and blogs for all teams
#   rake auto_blogs:evaluate - Generate evaluations for teams with summaries
#
namespace :auto_blogs do
  desc "Generate team blogs for all teams with summaries"
  task generate: :environment do
    puts "Starting automatic blog generation for teams with summaries..."
    
    # Find all team summaries with status 'success' that don't have blogs yet
    successful_summaries = TeamSummary.where(status: 'success')
    puts "Found #{successful_summaries.count} successful team summaries"
    
    blogs_created = 0
    
    successful_summaries.each do |summary|
      team_name = summary.team_name
      
      # Check if a blog already exists for this team
      existing_blog = TeamBlog.find_by(team_name: team_name)
      
      if existing_blog
        if existing_blog.status == 'success'
          puts "  - Team #{team_name} already has a successful blog, skipping"
          next
        elsif existing_blog.status == 'pending' || existing_blog.status == 'processing'
          puts "  - Team #{team_name} has a blog being generated, skipping"
          next
        else
          puts "  - Team #{team_name} has a failed blog, regenerating"
        end
      else
        puts "  - Team #{team_name} has no blog yet, generating"
      end
      
      # Queue job to generate team blog
      begin
        GenerateTeamBlogJob.perform_later(team_name)
        blogs_created += 1
        puts "  - Enqueued blog generation for #{team_name}"
      rescue => e
        puts "  - Error enqueueing job for #{team_name}: #{e.message}"
      end
    end
    
    puts "Completed. Enqueued #{blogs_created} blog generation jobs."
  end
  
  desc "Generate team summaries and blogs for all available teams"
  task generate_all: :environment do
    puts "Starting automatic summary and blog generation for all teams..."
    
    # Unique team names from successful submissions
    team_names = Submission.success.distinct.pluck(:team_name)
    puts "Found #{team_names.count} teams with successful submissions"
    
    summaries_created = 0
    
    team_names.each do |team_name|
      # Check if a summary already exists for this team
      existing_summary = TeamSummary.find_by(team_name: team_name)
      
      if existing_summary
        if existing_summary.status == 'success'
          puts "  - Team #{team_name} already has a successful summary, skipping"
          next
        elsif existing_summary.status == 'pending' || existing_summary.status == 'processing'
          puts "  - Team #{team_name} has a summary being generated, skipping"
          next
        else
          puts "  - Team #{team_name} has a failed summary, regenerating"
        end
      else
        puts "  - Team #{team_name} has no summary yet, generating"
      end
      
      # Queue job to generate team summary
      begin
        GenerateTeamSummaryJob.perform_later(team_name)
        summaries_created += 1
        puts "  - Enqueued summary generation for #{team_name}"
      rescue => e
        puts "  - Error enqueueing job for #{team_name}: #{e.message}"
      end
    end
    
    puts "Completed. Enqueued #{summaries_created} summary generation jobs."
    puts "Run 'rake auto_blogs:generate' after summaries are generated to create blogs."
  end
  
  desc "Generate team evaluations for all teams with summaries"
  task evaluate: :environment do
    puts "Starting automatic evaluation for teams with summaries..."
    
    # Find all team summaries with status 'success' that don't have evaluations yet
    successful_summaries = TeamSummary.where(status: 'success')
    puts "Found #{successful_summaries.count} successful team summaries"
    
    # Get or create default judging criteria
    criteria = JudgingCriterion.all
    
    if criteria.empty?
      puts "Creating default judging criteria..."
      default_criteria = [
        { name: "Innovation", description: "Originality and creativity of the solution", weight: 25 },
        { name: "Technical Complexity", description: "Sophistication and difficulty of implementation", weight: 25 },
        { name: "Impact", description: "Potential to solve real-world problems", weight: 25 },
        { name: "Presentation", description: "Quality of documentation and demonstration", weight: 25 }
      ]
      
      default_criteria.each do |criterion_data|
        JudgingCriterion.create!(criterion_data)
      end
      
      criteria = JudgingCriterion.all
    end
    
    criteria_ids = criteria.pluck(:id)
    puts "Using criteria IDs: #{criteria_ids.join(', ')}"
    
    evaluations_created = 0
    
    successful_summaries.each do |summary|
      team_name = summary.team_name
      
      # Check if an evaluation already exists for this team
      existing_evaluation = TeamEvaluation.find_by(team_name: team_name)
      
      if existing_evaluation
        if existing_evaluation.status == 'success'
          puts "  - Team #{team_name} already has a successful evaluation, skipping"
          next
        elsif existing_evaluation.status == 'pending' || existing_evaluation.status == 'processing'
          puts "  - Team #{team_name} has an evaluation being generated, skipping"
          next
        else
          puts "  - Team #{team_name} has a failed evaluation, regenerating"
        end
      else
        puts "  - Team #{team_name} has no evaluation yet, generating"
      end
      
      # Queue job to generate team evaluation
      begin
        EvaluateTeamJob.perform_later(team_name, criteria_ids)
        evaluations_created += 1
        puts "  - Enqueued evaluation for #{team_name}"
      rescue => e
        puts "  - Error enqueueing job for #{team_name}: #{e.message}"
      end
    end
    
    puts "Completed. Enqueued #{evaluations_created} evaluation jobs."
  end
end