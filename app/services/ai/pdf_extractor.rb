module Ai
  class PdfExtractor
    def initialize(client = nil)
      @client = client || Ai::Client.new
    end

    def process(submission, google_drive_service)
      file_content = google_drive_service.download_file(submission.source_url)

      # Use the AI client to extract text from the document
      response = @client.extract_text_from_document(file_content, submission.file_type)

      # Return the extracted text
      response
    end
  end
end
