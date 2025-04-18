require "sidekiq"

# Configure Redis connection
redis_config = {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
}

Sidekiq.configure_server do |config|
  config.redis = redis_config

  # Set server middleware
  config.server_middleware do |chain|
    # Add any middleware here
    # Example: chain.add MyCustomMiddleware
  end

  # Set client middleware
  config.client_middleware do |chain|
    # Add any middleware here
  end

  # Configure periodic tasks with Sidekiq-Scheduler if needed
  # if defined?(Sidekiq::Scheduler)
  #   Sidekiq::Scheduler.dynamic = true
  #   Sidekiq.schedule = YAML.load_file(File.expand_path('../../sidekiq_scheduler.yml', __FILE__))
  # end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config

  # Set client middleware
  config.client_middleware do |chain|
    # Add any middleware here
  end
end
