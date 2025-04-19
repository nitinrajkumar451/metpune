module ServiceErrorHandler
  # Load API error classes
  require_relative "../../errors/api_errors"

  def handle_request_error(service_name, error, additional_info = nil)
    case error
    when HTTParty::Error, Timeout::Error, SocketError
      log_error("#{service_name} network error", error, additional_info)
      raise ApiErrors::ExternalServiceError.new("Connection error: #{error.message}", service_name)
    when JSON::ParserError
      log_error("#{service_name} JSON parse error", error, additional_info)
      raise ApiErrors::ExternalServiceError.new("Invalid response from #{service_name}", service_name)
    else
      log_error("#{service_name} unexpected error", error, additional_info)
      raise ApiErrors::ExternalServiceError.new("Service error: #{error.message}", service_name)
    end
  end

  def handle_api_response(service_name, response, additional_info = nil)
    unless response.success?
      log_error("#{service_name} API error", nil, {
        code: response.code,
        body: response.body,
        additional: additional_info
      })

      error_message = begin
        response_body = JSON.parse(response.body)
        if response_body["error"].is_a?(Hash) && response_body["error"]["message"].present?
          response_body["error"]["message"]
        elsif response_body["error"].is_a?(String)
          response_body["error"]
        else
          "Unknown error"
        end
      rescue
        "Unknown error"
      end

      raise ApiErrors::ExternalServiceError.new("#{service_name} API error (#{response.code}): #{error_message}", service_name)
    end
  end

  def log_error(message, error = nil, additional_info = nil)
    error_log = { message: message }

    error_log[:error_class] = error.class.name if error
    error_log[:error_message] = error.message if error
    error_log[:backtrace] = error.backtrace.first(10) if error&.backtrace
    error_log[:additional_info] = additional_info if additional_info

    Rails.logger.error(error_log.to_json)

    # Report to error monitoring service in production
    if Rails.env.production? && defined?(ErrorReporter)
      context = {
        message: message,
        additional_info: additional_info
      }

      if error
        ErrorReporter.report(error, context)
      else
        # Create a generic error to report if no exception is provided
        generic_error = StandardError.new(message)
        ErrorReporter.report(generic_error, context)
      end
    end
  end
end
