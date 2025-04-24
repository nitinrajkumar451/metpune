module Api
  class TeamSummariesController < ApplicationController
    before_action :set_hackathon, except: [:index, :show, :generate]
    
    def index
      team_summaries = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        Hackathon.find(params[:hackathon_id]).team_summaries
      else
        # Legacy API support for non-nested routes
        TeamSummary.all
      end

      # Filter by status if provided
      team_summaries = team_summaries.where(status: params[:status]) if params[:status].present?

      render json: team_summaries
    end

    def show
      team_summary = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        Hackathon.find(params[:hackathon_id]).team_summaries.find_by(team_name: params[:team_name])
      else
        # Legacy API support for non-nested routes
        TeamSummary.find_by(team_name: params[:team_name])
      end

      if team_summary
        render json: team_summary
      else
        render json: { error: "Team summary not found" }, status: :not_found
      end
    end

    def generate
      team_name = params[:team_name]
      hackathon_id = params[:hackathon_id]

      if team_name.blank?
        return render json: { error: "Team name is required" }, status: :bad_request
      end

      # Get the hackathon (use provided ID or default)
      hackathon = hackathon_id ? Hackathon.find(hackathon_id) : Hackathon.default

      # Check if submissions exist for this team in this hackathon
      submissions_exist = Submission.success.where(team_name: team_name, hackathon_id: hackathon.id).exists?

      unless submissions_exist
        return render json: {
          error: "No successful submissions found for team: #{team_name} in hackathon: #{hackathon.name}"
        }, status: :bad_request
      end

      # Create or update the team summary record
      team_summary = TeamSummary.find_or_initialize_by(team_name: team_name, hackathon_id: hackathon.id)
      team_summary.update!(status: "pending")

      # Enqueue the job to generate the summary
      GenerateTeamSummaryJob.perform_later(team_name, hackathon.id)

      render json: { 
        message: "Team summary generation started for: #{team_name} in hackathon: #{hackathon.name}" 
      }, status: :ok
    end

    private

    def set_hackathon
      @hackathon = Hackathon.find(params[:hackathon_id])
    end
  end
end
