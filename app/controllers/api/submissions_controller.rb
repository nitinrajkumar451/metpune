module Api
  class SubmissionsController < ApplicationController
    before_action :set_hackathon, except: [:index, :show, :summaries, :start_ingestion]
    
    def index
      submissions = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        Hackathon.find(params[:hackathon_id]).submissions
      else
        # Legacy API support for non-nested routes
        Submission.all
      end

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
      submission = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        Hackathon.find(params[:hackathon_id]).submissions.find_by(id: params[:id])
      else
        # Legacy API support for non-nested routes
        Submission.find_by(id: params[:id])
      end

      if submission
        render json: submission
      else
        render json: { error: "Submission not found" }, status: :not_found
      end
    end

    def summaries
      # Get submissions filtered by hackathon if provided
      submissions = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        Hackathon.find(params[:hackathon_id]).submissions.success
      else
        # Legacy API support for non-nested routes
        Submission.success
      end

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
      Rails.logger.info "Starting document ingestion..."
      Rails.logger.info "Request parameters: #{params.inspect}"
      Rails.logger.info "Request headers: #{request.headers.env.select { |k, v| k.start_with?('HTTP_') }.inspect}"
      
      begin
        if params[:hackathon_id]
          Rails.logger.info "Hackathon ID provided: #{params[:hackathon_id]}"
          # Start ingestion for a specific hackathon if ID is provided
          hackathon = Hackathon.find(params[:hackathon_id])
          Rails.logger.info "Found hackathon: #{hackathon.name} (ID: #{hackathon.id})"
          
          # In development mode, perform synchronously for easier testing
          if Rails.env.development?
            Rails.logger.info "Development mode: Running job synchronously"
            IngestDocumentsJob.new.perform(hackathon.id)
            Rails.logger.info "Job completed synchronously"
            render json: { message: "Document ingestion completed for hackathon: #{hackathon.name}", job_id: "sync-#{SecureRandom.uuid}" }, status: :ok
          else
            job = IngestDocumentsJob.perform_later(hackathon.id)
            Rails.logger.info "Job enqueued: #{job.job_id}"
            render json: { message: "Document ingestion started for hackathon: #{hackathon.name}", job_id: job.job_id }, status: :ok
          end
        else
          # Legacy API support for non-nested routes - use default hackathon
          if Hackathon.default.nil?
            Rails.logger.error "No default hackathon found!"
            render json: { error: "No default hackathon found" }, status: :unprocessable_entity
            return
          end
          
          if Rails.env.development?
            Rails.logger.info "Development mode: Running job synchronously with default hackathon"
            IngestDocumentsJob.new.perform
            Rails.logger.info "Job completed synchronously"
            render json: { message: "Document ingestion completed for default hackathon", job_id: "sync-#{SecureRandom.uuid}" }, status: :ok
          else
            job = IngestDocumentsJob.perform_later
            Rails.logger.info "Job enqueued: #{job.job_id}"
            render json: { message: "Document ingestion started for default hackathon", job_id: job.job_id }, status: :ok
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "Record not found error: #{e.message}"
        render json: { error: "Hackathon not found with ID: #{params[:hackathon_id]}" }, status: :not_found
      rescue => e
        Rails.logger.error "Error in start_ingestion: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "An error occurred while starting ingestion: #{e.message}" }, status: :internal_server_error
      end
    end
    
    private
    
    def set_hackathon
      @hackathon = Hackathon.find(params[:hackathon_id]) if params[:hackathon_id]
    end
  end
end
