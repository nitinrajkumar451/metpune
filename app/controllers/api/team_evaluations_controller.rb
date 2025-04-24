module Api
  class TeamEvaluationsController < ApplicationController
    def index
      evaluations = TeamEvaluation.all

      # Filter by status if provided
      evaluations = evaluations.where(status: params[:status]) if params[:status].present?

      # Sort by score if requested
      if params[:sort_by] == "score"
        evaluations = evaluations.ordered_by_score
      end

      render json: evaluations
    end

    def show
      evaluation = TeamEvaluation.find_by(team_name: params[:team_name])

      if evaluation
        render json: evaluation
      else
        render json: { error: "Team evaluation not found" }, status: :not_found
      end
    end

    def generate
      team_name = params[:team_name]
      criteria_ids = params[:criteria_ids]

      if team_name.blank?
        return render json: { error: "Team name is required" }, status: :bad_request
      end

      # Verify team exists in TeamSummary
      team_summary = TeamSummary.find_by(team_name: team_name)

      unless team_summary&.status == "success"
        return render json: {
          error: "No successful team summary found for team: #{team_name}. Generate a team summary first."
        }, status: :bad_request
      end
      
      # If no criteria provided, use all existing criteria
      if criteria_ids.blank?
        criteria = JudgingCriterion.all
        
        if criteria.empty?
          # Create default criteria if none exist
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
      else
        # Validate provided criteria exist
        criteria = JudgingCriterion.where(id: criteria_ids)
        
        if criteria.empty?
          return render json: { error: "No valid judging criteria found" }, status: :bad_request
        end
      end

      # Create or update the team evaluation record
      evaluation = TeamEvaluation.find_or_initialize_by(team_name: team_name)
      evaluation.update!(status: "pending")

      # Enqueue the job to evaluate the team
      EvaluateTeamJob.perform_later(team_name, criteria_ids)

      render json: { message: "Team evaluation started for: #{team_name}" }, status: :ok
    end

    def leaderboard
      # Get all successful evaluations sorted by score
      evaluations = TeamEvaluation.success.ordered_by_score

      # Format the leaderboard data
      leaderboard = evaluations.map do |evaluation|
        {
          rank: nil, # We'll fill this in
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

      render json: { leaderboard: leaderboard }
    end
  end
end
