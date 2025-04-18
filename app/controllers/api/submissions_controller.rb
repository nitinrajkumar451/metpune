module Api
  class SubmissionsController < ApplicationController
    def index
      submissions = Submission.all
      
      # Apply filters if provided
      submissions = submissions.where(status: params[:status]) if params[:status].present?
      submissions = submissions.where(team_name: params[:team_name]) if params[:team_name].present?
      
      render json: submissions
    end
    
    def show
      submission = Submission.find_by(id: params[:id])
      
      if submission
        render json: submission
      else
        render json: { error: "Submission not found" }, status: :not_found
      end
    end
    
    def start_ingestion
      IngestDocumentsJob.perform_later
      
      render json: { message: "Document ingestion started" }, status: :ok
    end
  end
end