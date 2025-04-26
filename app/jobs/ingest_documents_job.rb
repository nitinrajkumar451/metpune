class IngestDocumentsJob < ApplicationJob
  queue_as :default

  # For MVP, we're only supporting PDF files
  SUPPORTED_FILE_TYPES = {
    "application/pdf" => "pdf"
    # Additional file types will be supported in future versions:
    # "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "docx",
    # "application/vnd.openxmlformats-officedocument.presentationml.presentation" => "pptx",
    # "image/jpeg" => "jpg",
    # "image/png" => "png",
    # "application/zip" => "zip"
  }

  def perform(hackathon_id = nil)
    # If no hackathon_id is provided, use the default hackathon
    hackathon = hackathon_id ? Hackathon.find(hackathon_id) : Hackathon.default
    
    Rails.logger.info("Starting document ingestion for hackathon: #{hackathon.name} (ID: #{hackathon.id})")
    
    google_drive_service = GoogleDriveService.new
    team_folders = google_drive_service.list_team_folders

    team_folders.each do |team_folder|
      process_team_folder(team_folder, google_drive_service, hackathon)
    end
  end

  private

  def process_team_folder(team_folder, google_drive_service, hackathon)
    files = google_drive_service.list_team_files(team_folder)

    files.each do |file|
      file_type = SUPPORTED_FILE_TYPES[file[:mime_type]]
      next unless file_type

      # Extract project name from the file path
      # Path format is: Metathon2025/TeamName/ProjectName/FileName
      path_parts = file[:path].split("/")
      project = path_parts.length >= 3 ? path_parts[-2] : "Default"

      # Find or create submission within this hackathon
      submission = Submission.find_or_initialize_by(
        hackathon_id: hackathon.id,
        team_name: team_folder,
        filename: file[:name]
      )
      
      submission.update!(
        file_type: file_type,
        source_url: file[:id],
        project: project,
        status: "processing"
      )

      process_submission(submission, google_drive_service)
    end
  end

  def process_submission(submission, google_drive_service)
    processor = processor_for_file_type(submission.file_type)

    begin
      Rails.logger.info("Processing submission #{submission.id} (#{submission.file_type})")
      summary = processor.process(submission, google_drive_service)

      if summary.present?
        # For MVP, we only store the summary directly (no separate raw_text)
        submission.update!(
          summary: summary,
          status: "success"
        )

        Rails.logger.info("Successfully processed submission #{submission.id}")
      else
        Rails.logger.error("No summary generated for submission #{submission.id}")
        submission.update!(status: "failed", summary: "Error: No summary could be generated")
      end
    rescue => e
      Rails.logger.error("Error processing submission #{submission.id}: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # Provide more detailed error info in development mode
      error_details = Rails.env.development? ? "#{e.class}: #{e.message}" : "Processing error"
      submission.update!(status: "failed", summary: "Error: #{error_details}")
    end
  end

  def processor_for_file_type(file_type)
    # For MVP, we only support PDF files
    if file_type == "pdf"
      Ai::PdfExtractor.new
    else
      raise ArgumentError, "Unsupported file type: #{file_type}. MVP only supports PDF files."
    end
    
    # Future implementation will support additional file types:
    # case file_type
    # when "pdf", "docx"
    #   Ai::PdfExtractor.new
    # when "pptx"
    #   Ai::PptxSummarizer.new
    # when "jpg", "png"
    #   Ai::OcrExtractor.new
    # when "zip"
    #   Ai::ZipProcessor.new
    # else
    #   raise ArgumentError, "Unsupported file type: #{file_type}"
    # end
  end
end
