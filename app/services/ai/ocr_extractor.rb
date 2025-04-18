module Ai
  class OcrExtractor
    def initialize(client = nil)
      @client = client || Ai::Client.new
    end

    def process(submission, google_drive_service)
      file_content = google_drive_service.download_file(submission.source_url)

      # Use the AI client to extract text from the image
      response = @client.extract_text_from_image(file_content)

      # Return the extracted text
      response
    end
  end
end
