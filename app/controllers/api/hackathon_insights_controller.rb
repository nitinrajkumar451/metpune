module Api
  class HackathonInsightsController < ApplicationController
    def index
      insight = HackathonInsight.success.latest.first

      if insight
        render json: insight
      else
        render json: { error: "No successful insights found" }, status: :not_found
      end
    end

    def generate
      # Check if there are any successful team summaries
      team_summaries = TeamSummary.success

      if team_summaries.empty?
        return render json: {
          error: "No successful team summaries found. Generate at least one team summary first."
        }, status: :bad_request
      end

      # Create a new insight record (will be updated by the job)
      insight = HackathonInsight.new(status: "pending")
      insight.save!

      # Enqueue the job to generate the insights
      GenerateHackathonInsightsJob.perform_later

      render json: { message: "Hackathon insights generation started" }, status: :ok
    end

    def markdown
      insight = HackathonInsight.success.latest.first

      if insight
        render plain: insight.content, content_type: "text/markdown"
      else
        render json: { error: "No successful insights found" }, status: :not_found
      end
    end
  end
end
