class GenerateTeamSummaryJob < ApplicationJob
  queue_as :default

  def perform(team_name)
    # Find or create the team summary record
    team_summary = TeamSummary.find_or_initialize_by(team_name: team_name)
    team_summary.update!(status: "processing")

    begin
      Rails.logger.info("Generating summary for team: #{team_name}")

      # Get all successful submissions for this team
      submissions = Submission.success.where(team_name: team_name)

      if submissions.any?
        # Format the submissions for the AI client
        formatted_submissions = submissions.map do |submission|
          {
            id: submission.id,
            filename: submission.filename,
            file_type: submission.file_type,
            project: submission.project,
            summary: submission.summary
          }
        end

        # Use the AI client to generate the team summary
        client = Ai::Client.new
        summary_content = client.generate_team_summary(team_name, formatted_submissions)

        # Update the team summary record
        team_summary.update!(content: summary_content, status: "success")
        Rails.logger.info("Successfully generated summary for team: #{team_name}")
      else
        # No submissions found
        error_message = "No successful submissions found for team: #{team_name}"
        Rails.logger.error(error_message)
        team_summary.update!(content: error_message, status: "failed")
      end
    rescue => e
      # Handle errors
      Rails.logger.error("Error generating team summary for #{team_name}: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # Provide more detailed error info in development mode
      error_details = Rails.env.development? ? "#{e.class}: #{e.message}" : "Processing error"
      team_summary.update!(content: "Error: #{error_details}", status: "failed")
    end
  end
end
