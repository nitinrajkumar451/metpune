module Api
  class HackathonInsightsController < ApplicationController
    before_action :set_hackathon, except: [:index, :generate, :markdown]
    
    def index
      insight = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        Hackathon.find(params[:hackathon_id]).hackathon_insights.success.latest.first
      else
        # Legacy API support for non-nested routes
        HackathonInsight.success.latest.first
      end

      if insight
        render json: insight
      else
        hackathon_context = params[:hackathon_id] ? " for this hackathon" : ""
        render json: { error: "No successful insights found#{hackathon_context}" }, status: :not_found
      end
    end

    def generate
      hackathon_id = params[:hackathon_id]
      
      # Get the hackathon (use provided ID or default)
      hackathon = hackathon_id ? Hackathon.find(hackathon_id) : Hackathon.default
      
      # Check if there are any successful team summaries for this hackathon
      team_summaries = TeamSummary.success.where(hackathon_id: hackathon.id)

      if team_summaries.empty?
        return render json: {
          error: "No successful team summaries found for hackathon: #{hackathon.name}. Generate at least one team summary first."
        }, status: :bad_request
      end

      # Create a new insight record (will be updated by the job)
      insight = HackathonInsight.new(status: "pending", hackathon_id: hackathon.id)
      insight.save!

      # Enqueue the job to generate the insights
      GenerateHackathonInsightsJob.perform_later(hackathon.id)

      render json: { 
        message: "Hackathon insights generation started for hackathon: #{hackathon.name}" 
      }, status: :ok
    end

    def markdown
      insight = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        Hackathon.find(params[:hackathon_id]).hackathon_insights.success.latest.first
      else
        # Legacy API support for non-nested routes
        HackathonInsight.success.latest.first
      end

      if insight
        render plain: insight.content, content_type: "text/markdown"
      else
        hackathon_context = params[:hackathon_id] ? " for this hackathon" : ""
        render json: { error: "No successful insights found#{hackathon_context}" }, status: :not_found
      end
    end
    
    private

    def set_hackathon
      @hackathon = Hackathon.find(params[:hackathon_id])
    end
  end
end
