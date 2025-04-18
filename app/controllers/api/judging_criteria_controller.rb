module Api
  class JudgingCriteriaController < ApplicationController
    def index
      criteria = JudgingCriterion.ordered
      render json: criteria
    end

    def show
      criterion = JudgingCriterion.find_by(id: params[:id])

      if criterion
        render json: criterion
      else
        render json: { error: "Judging criterion not found" }, status: :not_found
      end
    end

    def create
      criterion = JudgingCriterion.new(criterion_params)

      if criterion.save
        render json: criterion, status: :created
      else
        render json: { errors: criterion.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      criterion = JudgingCriterion.find_by(id: params[:id])

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
      criterion = JudgingCriterion.find_by(id: params[:id])

      if criterion.nil?
        render json: { error: "Judging criterion not found" }, status: :not_found
        return
      end

      criterion.destroy
      render json: { message: "Judging criterion deleted successfully" }
    end

    private

    def criterion_params
      params.require(:judging_criterion).permit(:name, :description, :weight)
    end
  end
end
