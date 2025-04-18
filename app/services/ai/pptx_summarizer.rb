module Ai
  class PptxSummarizer
    def initialize(client = nil)
      @client = client || Ai::Client.new
    end

    def process(submission, google_drive_service)
      file_content = google_drive_service.download_file(submission.source_url)

      # Use the AI client to extract slide-by-slide summaries
      slide_summaries = @client.summarize_presentation(file_content)

      # Generate an executive summary of the entire presentation
      executive_summary = @client.summarize_content(file_content, submission.file_type, slide_summaries)

      # Return both the slide-by-slide summaries and the executive summary
      {
        text: slide_summaries,
        summary: executive_summary
      }
    end
  end
end
