class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError

  # Set default queue (can be overridden in individual jobs)
  queue_as :default

  # Custom error handling
  rescue_from StandardError do |exception|
    # Log the error
    Rails.logger.error "Job Error: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")

    # Report to error tracking service if using one
    # ErrorReportingService.report(exception)

    # Re-raise the exception if needed
    raise exception
  end
end
