class GenerateTeamBlogJob < ApplicationJob
  queue_as :default

  def perform(team_name, hackathon_id = nil)
    # Get the hackathon (use provided ID or default)
    hackathon = hackathon_id ? Hackathon.find(hackathon_id) : Hackathon.default
    
    # Find or create the team blog record
    team_blog = TeamBlog.find_or_initialize_by(team_name: team_name, hackathon_id: hackathon.id)
    team_blog.update!(status: "processing")

    begin
      Rails.logger.info("Generating blog for team: #{team_name} in hackathon: #{hackathon.name}")

      # Get the team summary for this team in this hackathon
      team_summary = TeamSummary.find_by(team_name: team_name, hackathon_id: hackathon.id)

      if team_summary&.status == "success"
        # Use the AI client to generate the team blog
        client = Ai::Client.new
        blog_content = client.generate_team_blog(team_name, team_summary.content, hackathon.name)

        # Update the team blog record
        team_blog.update!(content: blog_content, status: "success")
        Rails.logger.info("Successfully generated blog for team: #{team_name} in hackathon: #{hackathon.name}")
      else
        # No successful team summary found
        error_message = "No successful team summary found for team: #{team_name} in hackathon: #{hackathon.name}"
        Rails.logger.error(error_message)
        team_blog.update!(content: error_message, status: "failed")
      end
    rescue => e
      # Handle errors
      Rails.logger.error("Error generating team blog for #{team_name} in hackathon: #{hackathon.name}: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # Provide more detailed error info in development mode
      error_details = Rails.env.development? ? "#{e.class}: #{e.message}" : "Processing error"
      team_blog.update!(content: "Error: #{error_details}", status: "failed")
    end
  end
end
