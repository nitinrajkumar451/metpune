module Api
  class TeamSummariesController < ApplicationController
    def index
      team_summaries = TeamSummary.all

      # Filter by status if provided
      team_summaries = team_summaries.where(status: params[:status]) if params[:status].present?

      render json: team_summaries
    end

    def show
      team_summary = TeamSummary.find_by(team_name: params[:team_name])

      if team_summary
        render json: team_summary
      else
        render json: { error: "Team summary not found" }, status: :not_found
      end
    end

    def generate
      team_name = params[:team_name]

      if team_name.blank?
        return render json: { error: "Team name is required" }, status: :bad_request
      end

      # Check if submissions exist for this team
      submissions_exist = Submission.success.where(team_name: team_name).exists?

      unless submissions_exist
        return render json: {
          error: "No successful submissions found for team: #{team_name}"
        }, status: :bad_request
      end

      # Create or update the team summary record
      team_summary = TeamSummary.find_or_initialize_by(team_name: team_name)
      team_summary.update!(status: "pending")

      # Enqueue the job to generate the summary
      GenerateTeamSummaryJob.perform_later(team_name)

      render json: { message: "Team summary generation started for: #{team_name}" }, status: :ok
    end
  end
end
