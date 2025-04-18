Rails.application.routes.draw do
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
    resources :submissions, only: [ :index, :show ]
    get "/summaries", to: "submissions#summaries"
    post "/start_ingestion", to: "submissions#start_ingestion"
  end
end
