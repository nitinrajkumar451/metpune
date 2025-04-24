class GenerateHackathonInsightsJob < ApplicationJob
  queue_as :default

  def perform(hackathon_id = nil)
    # Get the hackathon (use provided ID or default)
    hackathon = hackathon_id ? Hackathon.find(hackathon_id) : Hackathon.default
    
    # Create or update the hackathon insight record
    insight = HackathonInsight.new(status: "processing", hackathon_id: hackathon.id)
    insight.save!

    begin
      Rails.logger.info("Generating hackathon insights for hackathon: #{hackathon.name}")

      # Get all successful team summaries for this hackathon
      team_summaries = TeamSummary.success.where(hackathon_id: hackathon.id)

      if team_summaries.present?
        # Use the AI client to generate the insights
        client = Ai::Client.new
        insights_content = client.generate_hackathon_insights(team_summaries, hackathon.name)

        # Update the insight record
        insight.update!(content: insights_content, status: "success")
        Rails.logger.info("Successfully generated hackathon insights for hackathon: #{hackathon.name}")
      else
        # No successful team summaries found
        error_message = "No successful team summaries found to generate insights for hackathon: #{hackathon.name}"
        Rails.logger.error(error_message)
        insight.update!(content: error_message, status: "failed")
      end
    rescue => e
      # Handle errors
      Rails.logger.error("Error generating hackathon insights for hackathon: #{hackathon.name}: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # Provide more detailed error info in development mode
      error_details = Rails.env.development? ? "#{e.class}: #{e.message}" : "Processing error"
      insight.update!(content: "Error: #{error_details}", status: "failed")
    end
  end
end
