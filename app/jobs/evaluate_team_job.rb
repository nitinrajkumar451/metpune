class EvaluateTeamJob < ApplicationJob
  queue_as :default

  def perform(team_name, criteria_ids)
    # Find or create the team evaluation record
    team_evaluation = TeamEvaluation.find_or_initialize_by(team_name: team_name)

    # Initialize with empty scores to pass validation
    if team_evaluation.new_record? || team_evaluation.scores.blank?
      team_evaluation.scores = { "Placeholder" => { "score" => 0, "weight" => 1.0 } }
    end

    team_evaluation.update!(status: "processing")

    begin
      Rails.logger.info("Evaluating team: #{team_name}")

      # Check if there's a team summary
      team_summary = TeamSummary.find_by(team_name: team_name)

      unless team_summary&.status == "success"
        error_message = "No successful team summary found for team: #{team_name}"
        Rails.logger.error(error_message)
        team_evaluation.update!(
          status: "failed",
          comments: error_message
        )
        return
      end

      # Get the judging criteria
      criteria = JudgingCriterion.where(id: criteria_ids).map do |criterion|
        {
          name: criterion.name,
          description: criterion.description,
          weight: criterion.weight
        }
      end

      if criteria.empty?
        error_message = "No judging criteria found"
        Rails.logger.error(error_message)
        team_evaluation.update!(
          status: "failed",
          comments: error_message
        )
        return
      end

      # Use the AI client to evaluate the team
      client = Ai::Client.new
      evaluation_json = client.evaluate_team(team_name, team_summary.content, criteria)

      # Parse the JSON response
      begin
        if evaluation_json.is_a?(String)
          evaluation = JSON.parse(evaluation_json)
        else
          evaluation = evaluation_json
        end

        # Extract scores and comments
        scores = evaluation["scores"]
        total_score = evaluation["total_score"]
        comments = evaluation["comments"]

        # Update the team evaluation record
        team_evaluation.update!(
          scores: scores,
          total_score: total_score,
          comments: comments,
          status: "success"
        )

        Rails.logger.info("Successfully evaluated team: #{team_name}")
      rescue JSON::ParserError => e
        Rails.logger.error("Error parsing evaluation JSON: #{e.message}")
        Rails.logger.error("Raw JSON: #{evaluation_json}")

        team_evaluation.update!(
          status: "failed",
          comments: "Error parsing evaluation result: #{e.message}"
        )
      end
    rescue => e
      # Handle errors
      Rails.logger.error("Error evaluating team #{team_name}: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # Provide more detailed error info in development mode
      error_details = Rails.env.development? ? "#{e.class}: #{e.message}" : "Processing error"
      team_evaluation.update!(
        status: "failed",
        comments: "Error: #{error_details}"
      )
    end
  end
end
