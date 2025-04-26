module Api
  class JudgingCriteriaController < ApplicationController
    before_action :set_hackathon, except: [:index, :show, :create, :update, :destroy]
    
    def index
      criteria = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        # Use where to get the relation and then apply ordered scope
        JudgingCriterion.where(hackathon_id: params[:hackathon_id]).ordered
      else
        # Legacy API support for non-nested routes
        JudgingCriterion.ordered
      end
      
      render json: criteria
    end

    def show
      criterion = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        JudgingCriterion.find_by(id: params[:id], hackathon_id: params[:hackathon_id])
      else
        # Legacy API support for non-nested routes
        JudgingCriterion.find_by(id: params[:id])
      end

      if criterion
        render json: criterion
      else
        render json: { error: "Judging criterion not found" }, status: :not_found
      end
    end

    def create
      # Get the hackathon (use provided ID or default)
      hackathon_id = params[:hackathon_id] || (params[:judging_criterion] && params[:judging_criterion][:hackathon_id])
      hackathon = hackathon_id ? Hackathon.find(hackathon_id) : Hackathon.default
      
      # Build criterion with params and set hackathon
      criterion = JudgingCriterion.new(criterion_params)
      criterion.hackathon = hackathon

      if criterion.save
        render json: criterion, status: :created
      else
        render json: { errors: criterion.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      criterion = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        JudgingCriterion.find_by(id: params[:id], hackathon_id: params[:hackathon_id])
      else
        # Legacy API support for non-nested routes
        JudgingCriterion.find_by(id: params[:id])
      end

      if criterion.nil?
        render json: { error: "Judging criterion not found" }, status: :not_found
        return
      end

      if criterion.update(criterion_params)
        render json: criterion
      else
        render json: { errors: criterion.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      criterion = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        JudgingCriterion.find_by(id: params[:id], hackathon_id: params[:hackathon_id])
      else
        # Legacy API support for non-nested routes
        JudgingCriterion.find_by(id: params[:id])
      end

      if criterion.nil?
        render json: { error: "Judging criterion not found" }, status: :not_found
        return
      end

      criterion.destroy
      render json: { message: "Judging criterion deleted successfully" }
    end

    private
    
    def set_hackathon
      @hackathon = Hackathon.find(params[:hackathon_id])
    end

    def criterion_params
      # Allow hackathon_id if it's provided for legacy API
      params.require(:judging_criterion).permit(:name, :description, :weight, :hackathon_id)
    end
  end
end
