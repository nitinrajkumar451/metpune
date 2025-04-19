module ApiErrors
  # Base API error class
  class ApiError < StandardError
    attr_reader :status, :error_code, :details

    def initialize(message = nil, status = :bad_request, error_code = nil, details = nil)
      @status = status
      @error_code = error_code || status
      @details = details
      super(message || "An error occurred with the API request")
    end
  end

  class InvalidParameterError < ApiError
    def initialize(message = nil, details = nil)
      super(message || "Invalid parameters", :bad_request, "invalid_parameters", details)
    end
  end

  class ResourceNotFoundError < ApiError
    def initialize(message = nil, details = nil)
      super(message || "Resource not found", :not_found, "not_found", details)
    end
  end

  class UnauthorizedError < ApiError
    def initialize(message = nil, details = nil)
      super(message || "Unauthorized access", :unauthorized, "unauthorized", details)
    end
  end

  class ForbiddenError < ApiError
    def initialize(message = nil, details = nil)
      super(message || "Forbidden access", :forbidden, "forbidden", details)
    end
  end

  class DependencyError < ApiError
    def initialize(message = nil, details = nil)
      super(message || "Dependency missing or invalid", :bad_request, "dependency_error", details)
    end
  end

  class ExternalServiceError < ApiError
    def initialize(message = nil, service = nil)
      details = service ? { service: service } : nil
      super(message || "External service error", :service_unavailable, "external_service_error", details)
    end
  end

  class AiServiceError < ExternalServiceError
    def initialize(message = nil, provider = nil)
      super(message || "AI service error", provider || "AI Provider")
    end
  end

  class GoogleDriveError < ExternalServiceError
    def initialize(message = nil)
      super(message || "Google Drive service error", "Google Drive")
    end
  end
end
