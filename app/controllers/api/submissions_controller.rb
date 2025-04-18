module Api
  class SubmissionsController < ApplicationController
    def index
      submissions = Submission.all

      # Apply filters if provided
      submissions = submissions.where(status: params[:status]) if params[:status].present?
      submissions = submissions.where(team_name: params[:team_name]) if params[:team_name].present?
      submissions = submissions.where(project: params[:project]) if params[:project].present?

      # Support summaries_only mode to just fetch the summaries
      if params[:summaries_only] == "true"
        render json: submissions, each_serializer: SubmissionSummarySerializer
      else
        render json: submissions
      end
    end

    def show
      submission = Submission.find_by(id: params[:id])

      if submission
        render json: submission
      else
        render json: { error: "Submission not found" }, status: :not_found
      end
    end

    def summaries
      # Get successful submissions
      submissions = Submission.success

      # Group by team and then by project
      grouped_submissions = submissions.group_by(&:team_name).transform_values do |team_submissions|
        team_submissions.group_by(&:project)
      end

      # Format the response
      result = grouped_submissions.transform_values do |projects_hash|
        projects_hash.transform_values do |project_submissions|
          project_submissions.map do |submission|
            {
              id: submission.id,
              filename: submission.filename,
              file_type: submission.file_type,
              summary: submission.summary,
              created_at: submission.created_at
            }
          end
        end
      end

      render json: result
    end

    def start_ingestion
      IngestDocumentsJob.perform_later

      render json: { message: "Document ingestion started" }, status: :ok
    end
  end
end
