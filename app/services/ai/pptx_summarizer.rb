module Ai
  class PptxSummarizer
    def initialize(client = nil)
      @client = client || Ai::Client.new
    end

    def process(submission, google_drive_service)
      file_content = google_drive_service.download_file(submission.source_url)

      # Use the AI client to summarize the presentation
      response = @client.summarize_presentation(file_content)

      # Return the summaries
      response
    end
  end
end
