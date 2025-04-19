module Ai
  class PdfExtractor
    def initialize(client = nil)
      @client = client || Ai::Client.new
    end

    def process(submission, google_drive_service)
      file_content = google_drive_service.download_file(submission.source_url)

      # For MVP, generate summary directly from PDF content
      # Skip the separate text extraction step
      summary = @client.generate_pdf_summary(file_content)

      # For MVP, we only need to return the summary
      # The raw text extraction is skipped
      summary
    end
  end
end
