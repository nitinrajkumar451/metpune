module Api
  class TeamBlogsController < ApplicationController
    def index
      team_blogs = TeamBlog.all

      # Filter by status if provided
      team_blogs = team_blogs.where(status: params[:status]) if params[:status].present?

      render json: team_blogs
    end

    def show
      team_blog = TeamBlog.find_by(team_name: params[:team_name])

      if team_blog
        render json: team_blog
      else
        render json: { error: "Team blog not found" }, status: :not_found
      end
    end

    def generate
      team_name = params[:team_name]

      if team_name.blank?
        return render json: { error: "Team name is required" }, status: :bad_request
      end

      # Check if team summary exists for this team
      team_summary = TeamSummary.find_by(team_name: team_name)

      unless team_summary&.status == "success"
        return render json: {
          error: "No successful team summary found for team: #{team_name}. Generate a team summary first."
        }, status: :bad_request
      end

      # Create or update the team blog record
      team_blog = TeamBlog.find_or_initialize_by(team_name: team_name)
      team_blog.update!(status: "pending")

      # Enqueue the job to generate the blog
      GenerateTeamBlogJob.perform_later(team_name)

      render json: { message: "Team blog generation started for: #{team_name}" }, status: :ok
    end

    def markdown
      team_blog = TeamBlog.find_by(team_name: params[:team_name])

      if team_blog&.status == "success"
        render plain: team_blog.content, content_type: "text/markdown"
      else
        render json: { error: "No successful blog found for team: #{params[:team_name]}" }, status: :not_found
      end
    end
  end
end
