module ErrorHandler
  extend ActiveSupport::Concern

  included do
    # Load API error classes
    require_relative "../../errors/api_errors"

    # Handle custom API errors
    rescue_from ApiErrors::ApiError, with: :handle_api_error

    # Custom handlers for other common errors
    rescue_from StandardError, with: :handle_standard_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  end

  private

  def handle_api_error(exception)
    response = {
      error: exception.message,
      error_code: exception.error_code
    }

    response[:details] = exception.details if exception.details.present?

    render json: response, status: exception.status
  end

  def handle_standard_error(exception)
    # Log the error for server monitoring
    Rails.logger.error "ERROR: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n") if exception.backtrace.present?

    # Report to error monitoring service in production
    report_error(exception) if Rails.env.production? && defined?(ErrorReporter)

    # In production, don't expose error details to the client
    if Rails.env.production?
      render json: { error: "Internal server error", error_code: "internal_error" }, status: :internal_server_error
    else
      # In development and test, include more information
      render json: {
        error: "#{exception.class}: #{exception.message}",
        error_code: "internal_error",
        backtrace: exception.backtrace&.first(10)
      }, status: :internal_server_error
    end
  end

  def handle_not_found(exception)
    render json: {
      error: exception.message || "Resource not found",
      error_code: "not_found"
    }, status: :not_found
  end

  def handle_validation_error(exception)
    render json: {
      error: "Validation failed",
      error_code: "validation_error",
      details: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def handle_parameter_missing(exception)
    render json: {
      error: exception.message,
      error_code: "missing_parameter"
    }, status: :bad_request
  end

  def report_error(exception, context = {})
    # Only use ErrorReporter if available
    return unless defined?(ErrorReporter)

    # Add controller and action to context
    context.merge!({
      controller: self.class.name,
      action: action_name,
      params: request.filtered_parameters
    })

    # Report to error service
    ErrorReporter.report(exception, context)
  end
end
