require "zip"
require "stringio"

module Ai
  class ZipProcessor
    def initialize(client = nil)
      @client = client || Ai::Client.new
    end

    def process(submission, google_drive_service)
      file_content = google_drive_service.download_file(submission.source_url)

      # Process the ZIP archive and extract content from each file
      response = process_zip_archive(file_content)

      # Return the processed content
      response
    end

    private

    def process_zip_archive(file_content)
      # Skip real processing in development/test
      return mock_zip_response unless Rails.env.production?

      begin
        # Real implementation - extract and process files
        extracted_content = []

        # Create a stream from the file content
        zip_io = StringIO.new(file_content)
        Zip::File.open_buffer(zip_io) do |zip_file|
          zip_file.each do |entry|
            # Skip directories and very large files
            next if entry.directory? || entry.size > 10.megabytes

            # Extract the file content
            content = entry.get_input_stream.read

            # Process the file based on its extension
            extracted_text = extract_from_zip_entry(entry.name, content)
            extracted_content << "- #{entry.name}: #{extracted_text}"
          end
        end

        # Return the combined extraction results
        extracted_content.join("\n\n")
      rescue StandardError => e
        # Re-raise the error
        raise e
      end
    end

    def extract_from_zip_entry(filename, content)
      # Determine file type from extension
      extension = File.extname(filename).delete(".").downcase

      case extension
      when "pdf", "docx"
        @client.extract_text_from_document(content, extension)
      when "pptx"
        @client.summarize_presentation(content)
      when "jpg", "jpeg", "png"
        @client.extract_text_from_image(content)
      else
        "File type not supported for extraction"
      end
    end

    def mock_zip_response
      "Extracted ZIP contents:\n\n" +
      "- document1.pdf: Text content from document 1\n" +
      "- document2.docx: Text content from document 2\n" +
      "- presentation.pptx: Slide summaries from the presentation\n" +
      "- image.jpg: OCR text extracted from the image"
    end
  end
end
