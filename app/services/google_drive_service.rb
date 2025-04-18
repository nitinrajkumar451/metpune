require "google/apis/drive_v3"

class GoogleDriveService
  def initialize
    @drive_service = Google::Apis::DriveV3::DriveService.new
    @drive_service.authorization = authorize
  end

  def list_team_folders
    if Rails.env.production?
      # In production, use the real Google Drive API
      metathon_folder_response = @drive_service.list_files(
        q: "name = 'Metathon2025' and mimeType = 'application/vnd.google-apps.folder'",
        fields: "files(id, name)"
      )

      return [] if metathon_folder_response.files.empty?

      metathon_folder_id = metathon_folder_response.files.first.id

      # Now find all team folders within Metathon2025
      team_folders_response = @drive_service.list_files(
        q: "'#{metathon_folder_id}' in parents and mimeType = 'application/vnd.google-apps.folder'",
        fields: "files(id, name)"
      )

      team_folders_response.files.map(&:name)
    else
      # In development/test, return mock data
      ["Team1", "Team2", "Team3"]
    end
  end

  def list_team_files(team_name)
    if Rails.env.production?
      # In production, use the real Google Drive API
      metathon_folder_response = @drive_service.list_files(
        q: "name = 'Metathon2025' and mimeType = 'application/vnd.google-apps.folder'",
        fields: "files(id, name)"
      )

      return [] if metathon_folder_response.files.empty?

      metathon_folder_id = metathon_folder_response.files.first.id

      # Find the team folder
      team_folder_response = @drive_service.list_files(
        q: "name = '#{team_name}' and mimeType = 'application/vnd.google-apps.folder' and '#{metathon_folder_id}' in parents",
        fields: "files(id, name, mimeType)"
      )

      return [] if team_folder_response.files.empty?

      team_folder_id = team_folder_response.files.first.id

      # List all files in the team folder
      files_response = @drive_service.list_files(
        q: "'#{team_folder_id}' in parents",
        fields: "files(id, name, mimeType)"
      )

      files_response.files.map do |file|
        {
          id: file.id,
          name: file.name,
          mime_type: file.mime_type,
          path: "Metathon2025/#{team_name}/#{file.name}"
        }
      end
    else
      # In development/test, return mock data representing multiple files
      # Each team has a project folder with multiple files inside
      mock_files = []
      
      # Project 1 files
      project1_files = [
        { id: "#{team_name}_proj1_file1", name: 'project_description.pdf', mime_type: 'application/pdf', path: "Metathon2025/#{team_name}/Project1/project_description.pdf" },
        { id: "#{team_name}_proj1_file2", name: 'presentation.pptx', mime_type: 'application/vnd.openxmlformats-officedocument.presentationml.presentation', path: "Metathon2025/#{team_name}/Project1/presentation.pptx" },
        { id: "#{team_name}_proj1_file3", name: 'architecture_diagram.jpg', mime_type: 'image/jpeg', path: "Metathon2025/#{team_name}/Project1/architecture_diagram.jpg" }
      ]
      
      # Project 2 files
      project2_files = [
        { id: "#{team_name}_proj2_file1", name: 'technical_specs.docx', mime_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', path: "Metathon2025/#{team_name}/Project2/technical_specs.docx" },
        { id: "#{team_name}_proj2_file2", name: 'screenshot.png', mime_type: 'image/png', path: "Metathon2025/#{team_name}/Project2/screenshot.png" }
      ]
      
      # Source code archive
      source_code = [
        { id: "#{team_name}_src_file1", name: 'source_code.zip', mime_type: 'application/zip', path: "Metathon2025/#{team_name}/SourceCode/source_code.zip" }
      ]
      
      # Add all files to the mock files list
      mock_files.concat(project1_files)
      mock_files.concat(project2_files)
      mock_files.concat(source_code)
      
      mock_files
    end
  end

  def download_file(file_id)
    if Rails.env.production?
      content_io = StringIO.new
      begin
        # Try direct download first
        @drive_service.get_file(file_id, download_dest: content_io)
      rescue Google::Apis::ClientError => e
        # If it's a Google Document, try to export it as PDF
        @drive_service.export_file(file_id, 'application/pdf', download_dest: content_io)
      end
      content_io.string
    else
      # In development/test, return mock content based on file ID pattern
      if file_id.include?('pdf') || file_id.include?('docx')
        "Sample document content for file #{file_id}"
      elsif file_id.include?('pptx')
        "Sample presentation content for file #{file_id}"
      elsif file_id.include?('jpg') || file_id.include?('png')
        "Sample image binary data for file #{file_id}"
      elsif file_id.include?('zip')
        "Sample ZIP archive binary data for file #{file_id}"
      else
        "Sample content for file #{file_id}"
      end
    end
  end

  private
  def authorize
    if Rails.env.production? || Rails.env.development?
      # Try to use environment variables first
      if ENV['GOOGLE_DRIVE_SERVICE_ACCOUNT_JSON']
        # Service account authentication (recommended for backend)
        require 'googleauth'
        
        # Use service account JSON from environment variable
        json_key_data = ENV['GOOGLE_DRIVE_SERVICE_ACCOUNT_JSON']
        credentials = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: StringIO.new(json_key_data),
          scope: Google::Apis::DriveV3::AUTH_DRIVE_READONLY
        )
        credentials.fetch_access_token!
        credentials
      elsif ENV['GOOGLE_DRIVE_CREDENTIALS_PATH'] && File.exist?(ENV['GOOGLE_DRIVE_CREDENTIALS_PATH'])
        # Use service account JSON file from specified path
        require 'googleauth'
        
        credentials = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: File.open(ENV['GOOGLE_DRIVE_CREDENTIALS_PATH']),
          scope: Google::Apis::DriveV3::AUTH_DRIVE_READONLY
        )
        credentials.fetch_access_token!
        credentials
      elsif Rails.application.credentials.dig(:google_drive, :service_account)
        # Use credentials from Rails credentials system
        require 'googleauth'
        
        # Extract credentials from Rails credentials
        credentials_hash = {
          "type" => "service_account",
          "project_id" => Rails.application.credentials.dig(:google_drive, :project_id),
          "private_key_id" => Rails.application.credentials.dig(:google_drive, :private_key_id),
          "private_key" => Rails.application.credentials.dig(:google_drive, :private_key),
          "client_email" => Rails.application.credentials.dig(:google_drive, :client_email),
          "client_id" => Rails.application.credentials.dig(:google_drive, :client_id),
          "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
          "token_uri" => "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url" => Rails.application.credentials.dig(:google_drive, :client_x509_cert_url)
        }
        
        # Create credentials from hash
        credentials = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: StringIO.new(credentials_hash.to_json),
          scope: Google::Apis::DriveV3::AUTH_DRIVE_READONLY
        )
        credentials.fetch_access_token!
        credentials
      else
        # Fall back to nil - will cause API requests to fail with auth errors
        Rails.logger.warn("No Google Drive credentials found. API requests will fail.")
        nil
      end
    else
      # In test environment, return nil (authentication is mocked)
      nil
    end
  rescue StandardError => e
    Rails.logger.error("Failed to authenticate with Google Drive API: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    nil # Return nil instead of raising to allow the app to start, but API requests will fail
  end
end
