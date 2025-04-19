# Configure error reporting/monitoring in production
if Rails.env.production?
  # Uncomment and configure your error reporting service here

  # Example 1: If using Sentry
  # Raven.configure do |config|
  #   config.dsn = ENV['SENTRY_DSN']
  #   config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  #   config.environments = ['production']
  # end

  # Example 2: If using Honeybadger
  # Honeybadger.configure do |config|
  #   config.api_key = ENV['HONEYBADGER_API_KEY']
  #   config.environment_name = Rails.env
  # end

  # Example 3: If using New Relic
  # NewRelic::Agent.manual_start

  # Define a method to report errors to your service
  module ErrorReporter
    def self.report(exception, context = {})
      # Log all errors to Rails logger
      Rails.logger.error "ERROR: #{exception.class} - #{exception.message}"
      Rails.logger.error exception.backtrace.join("\n") if exception.backtrace
      Rails.logger.error "Context: #{context.inspect}" if context.present?

      # Report to your service of choice
      # Uncomment one of these based on your chosen service

      # Raven.capture_exception(exception, extra: context)
      # Honeybadger.notify(exception, context: context)
      # NewRelic::Agent.notice_error(exception, custom_params: context)
    end
  end
else
  # In development and test, just define a stub reporter
  module ErrorReporter
    def self.report(exception, context = {})
      # In non-production environments, just log
      Rails.logger.error "ERROR: #{exception.class} - #{exception.message}"
      Rails.logger.error exception.backtrace.join("\n") if exception.backtrace
      Rails.logger.error "Context: #{context.inspect}" if context.present?
    end
  end
end
