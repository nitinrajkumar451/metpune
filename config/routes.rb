require "sidekiq/web"

Rails.application.routes.draw do
  # Mount Sidekiq web interface with basic auth in production
  if Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      # Enable in your deployment with proper credentials
      # ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_USERNAME'])) &
      # ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_PASSWORD']))

      # For now, disable in production until configured
      false
    end
  end

  # Mount the Sidekiq web UI at /sidekiq
  mount Sidekiq::Web => "/sidekiq"
  # Try to load Rswag if available
  begin
    mount Rswag::Ui::Engine => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  rescue NameError => e
    Rails.logger.warn "Rswag engines not loaded. Using custom route for Swagger documentation."

    # Add a direct route to serve the swagger.yaml file
    get "api-docs/v1/swagger.yaml", to: lambda { |env|
      file_path = Rails.root.join("swagger", "v1", "swagger.yaml")
      if File.exist?(file_path)
        [ 200, { "Content-Type" => "application/yaml" }, [ File.read(file_path) ] ]
      else
        [ 404, { "Content-Type" => "text/plain" }, [ "Swagger documentation not found" ] ]
      end
    }

    # Add a simple HTML page for API documentation
    get "api-docs", to: lambda { |env|
      [ 200, { "Content-Type" => "text/html" }, [ <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>Metathon API Documentation</title>
            <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
            <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css">
            <style>
              body { margin: 0; padding: 0; }
              #swagger-ui { margin: 0 auto; max-width: 1460px; }
            </style>
          </head>
          <body>
            <div id="swagger-ui"></div>
            <script>
              window.onload = function() {
                SwaggerUIBundle({
                  url: "/api-docs/v1/swagger.yaml",
                  dom_id: '#swagger-ui',
                  presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIBundle.SwaggerUIStandalonePreset
                  ],
                  layout: "BaseLayout"
                });
              }
            </script>
          </body>
        </html>
      HTML
      ] ]
    }
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    # Hackathon resources
    resources :hackathons do
      # Submissions endpoints (nested under hackathon)
      resources :submissions, only: [ :index, :show ]
      get "/summaries", to: "submissions#summaries"
      post "/start_ingestion", to: "submissions#start_ingestion"

      # Team summaries endpoints (nested under hackathon)
      resources :team_summaries, only: [ :index ]
      get "/team_summaries/:team_name", to: "team_summaries#show"
      post "/team_summaries/generate", to: "team_summaries#generate"

      # Judging criteria endpoints (nested under hackathon)
      resources :judging_criteria

      # Team evaluations endpoints (nested under hackathon)
      resources :team_evaluations, only: [ :index ]
      get "/team_evaluations/:team_name", to: "team_evaluations#show"
      post "/team_evaluations/generate", to: "team_evaluations#generate"
      get "/team_evaluations/status", to: "team_evaluations#status"
      get "/leaderboard", to: "team_evaluations#leaderboard"

      # Team blogs endpoints (nested under hackathon)
      resources :team_blogs, only: [ :index ]
      get "/team_blogs/:team_name", to: "team_blogs#show"
      get "/team_blogs/:team_name/markdown", to: "team_blogs#markdown"
      post "/team_blogs/generate", to: "team_blogs#generate"

      # Hackathon insights endpoints (nested under hackathon)
      get "/hackathon_insights", to: "hackathon_insights#index"
      get "/hackathon_insights/markdown", to: "hackathon_insights#markdown"
      post "/hackathon_insights/generate", to: "hackathon_insights#generate"
    end
    
    # Legacy endpoints (kept for backward compatibility)
    resources :submissions, only: [ :index, :show ]
    get "/summaries", to: "submissions#summaries"
    post "/start_ingestion", to: "submissions#start_ingestion"

    resources :team_summaries, only: [ :index ]
    get "/team_summaries/:team_name", to: "team_summaries#show"
    post "/team_summaries/generate", to: "team_summaries#generate"

    resources :judging_criteria

    resources :team_evaluations, only: [ :index ]
    get "/team_evaluations/:team_name", to: "team_evaluations#show"
    post "/team_evaluations/generate", to: "team_evaluations#generate"
    get "/team_evaluations/status", to: "team_evaluations#status"
    get "/leaderboard", to: "team_evaluations#leaderboard"

    resources :team_blogs, only: [ :index ]
    get "/team_blogs/:team_name", to: "team_blogs#show"
    get "/team_blogs/:team_name/markdown", to: "team_blogs#markdown"
    post "/team_blogs/generate", to: "team_blogs#generate"

    get "/hackathon_insights", to: "hackathon_insights#index"
    get "/hackathon_insights/markdown", to: "hackathon_insights#markdown"
    post "/hackathon_insights/generate", to: "hackathon_insights#generate"
  end
end
