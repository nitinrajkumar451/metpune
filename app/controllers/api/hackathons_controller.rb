module Api
  class HackathonsController < ApplicationController
    def index
      hackathons = Hackathon.all.order(created_at: :desc)
      render json: hackathons
    end
    
    def show
      hackathon = Hackathon.find(params[:id])
      render json: hackathon
    end
    
    def create
      hackathon = Hackathon.new(hackathon_params)
      
      if hackathon.save
        render json: hackathon, status: :created
      else
        render json: { errors: hackathon.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    def update
      hackathon = Hackathon.find(params[:id])
      
      if hackathon.update(hackathon_params)
        render json: hackathon
      else
        render json: { errors: hackathon.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    def destroy
      hackathon = Hackathon.find(params[:id])
      hackathon.destroy
      head :no_content
    end
    
    private
    
    def hackathon_params
      params.require(:hackathon).permit(:name, :description, :start_date, :end_date, :status)
    end
  end
end