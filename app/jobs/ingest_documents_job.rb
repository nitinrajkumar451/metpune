class IngestDocumentsJob < ApplicationJob
  queue_as :default

  SUPPORTED_FILE_TYPES = {
    'application/pdf' => 'pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'docx',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'pptx',
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'application/zip' => 'zip'
  }

  def perform
    google_drive_service = GoogleDriveService.new
    team_folders = google_drive_service.list_team_folders
    
    team_folders.each do |team_folder|
      process_team_folder(team_folder, google_drive_service)
    end
  end
  
  private
  
  def process_team_folder(team_folder, google_drive_service)
    files = google_drive_service.list_team_files(team_folder)
    
    files.each do |file|
      file_type = SUPPORTED_FILE_TYPES[file[:mime_type]]
      next unless file_type
      
      submission = Submission.create!(
        team_name: team_folder,
        filename: file[:name],
        file_type: file_type,
        source_url: file[:id],
        status: 'processing'
      )
      
      process_submission(submission, google_drive_service)
    end
  end
  
  def process_submission(submission, google_drive_service)
    processor = processor_for_file_type(submission.file_type)
    
    begin
      raw_text = processor.process(submission, google_drive_service)
      submission.update!(raw_text: raw_text, status: 'success')
    rescue StandardError => e
      Rails.logger.error("Error processing submission #{submission.id}: #{e.message}")
      submission.update!(status: 'failed')
    end
  end
  
  def processor_for_file_type(file_type)
    case file_type
    when 'pdf', 'docx'
      AI::PdfExtractor.new
    when 'pptx'
      AI::PptxSummarizer.new
    when 'jpg', 'png'
      AI::OcrExtractor.new
    when 'zip'
      AI::ZipProcessor.new
    else
      raise ArgumentError, "Unsupported file type: #{file_type}"
    end
  end
end