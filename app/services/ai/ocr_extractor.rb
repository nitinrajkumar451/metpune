module Ai
  class OcrExtractor
    def initialize(client = nil)
      @client = client || Ai::Client.new
    end

    def process(submission, google_drive_service)
      file_content = google_drive_service.download_file(submission.source_url)

      # Use the AI client to extract text from the image
      extracted_text = @client.extract_text_from_image(file_content)

      # Generate a summary using the extracted text
      summary = @client.summarize_content(file_content, submission.file_type, extracted_text)

      # Return both the extracted text and summary
      {
        text: extracted_text,
        summary: summary
      }
    end
  end
end
