module Api
  class TeamBlogsController < ApplicationController
    before_action :set_hackathon, except: [:index, :show, :generate, :markdown]
    
    def index
      team_blogs = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        Hackathon.find(params[:hackathon_id]).team_blogs
      else
        # Legacy API support for non-nested routes
        TeamBlog.all
      end

      # Filter by status if provided
      team_blogs = team_blogs.where(status: params[:status]) if params[:status].present?

      render json: team_blogs
    end

    def show
      team_blog = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        Hackathon.find(params[:hackathon_id]).team_blogs.find_by(team_name: params[:team_name])
      else
        # Legacy API support for non-nested routes
        TeamBlog.find_by(team_name: params[:team_name])
      end

      if team_blog
        render json: team_blog
      else
        render json: { error: "Team blog not found" }, status: :not_found
      end
    end

    def generate
      team_name = params[:team_name]
      hackathon_id = params[:hackathon_id]

      if team_name.blank?
        return render json: { error: "Team name is required" }, status: :bad_request
      end

      # Get the hackathon (use provided ID or default)
      hackathon = hackathon_id ? Hackathon.find(hackathon_id) : Hackathon.default

      # Check if team summary exists for this team in this hackathon
      team_summary = TeamSummary.find_by(team_name: team_name, hackathon_id: hackathon.id)

      unless team_summary&.status == "success"
        return render json: {
          error: "No successful team summary found for team: #{team_name} in hackathon: #{hackathon.name}. Generate a team summary first."
        }, status: :bad_request
      end

      # Create or update the team blog record
      team_blog = TeamBlog.find_or_initialize_by(team_name: team_name, hackathon_id: hackathon.id)
      team_blog.update!(status: "pending")

      # Enqueue the job to generate the blog
      GenerateTeamBlogJob.perform_later(team_name, hackathon.id)

      render json: { 
        message: "Team blog generation started for: #{team_name} in hackathon: #{hackathon.name}" 
      }, status: :ok
    end

    def markdown
      team_blog = if params[:hackathon_id]
        # If hackathon_id is provided via nested route
        Hackathon.find(params[:hackathon_id]).team_blogs.find_by(team_name: params[:team_name])
      else
        # Legacy API support for non-nested routes
        TeamBlog.find_by(team_name: params[:team_name])
      end

      if team_blog&.status == "success"
        render plain: team_blog.content, content_type: "text/markdown"
      else
        hackathon_context = params[:hackathon_id] ? " in this hackathon" : ""
        render json: { 
          error: "No successful blog found for team: #{params[:team_name]}#{hackathon_context}" 
        }, status: :not_found
      end
    end
    
    private

    def set_hackathon
      @hackathon = Hackathon.find(params[:hackathon_id])
    end
  end
end
