require "google/apis/drive_v3"
require_relative "concerns/service_error_handler"

class GoogleDriveService
  include ServiceErrorHandler
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
      # In development/test, return mock data for local testing
      setup_local_test_files unless File.directory?(Rails.root.join("tmp/mock_drive"))

      # Get actual team folders from the mock_drive directory
      team_folders = Dir.glob(Rails.root.join("tmp/mock_drive", "*")).select do |f|
        File.directory?(f)
      end.map do |f|
        File.basename(f)
      end

      team_folders
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
      # For local testing, return PDF files from our local mock directory
      setup_local_test_files unless File.directory?(Rails.root.join("tmp/mock_drive"))

      # Get local files for the team from our mock directory
      team_directory = Rails.root.join("tmp/mock_drive", team_name)
      return [] unless File.directory?(team_directory)

      file_paths = Dir.glob(File.join(team_directory, "**", "*.pdf"))

      file_paths.map do |file_path|
        relative_path = file_path.sub(%r{^#{Rails.root.join('tmp/mock_drive')}/}, "")
        file_name = File.basename(file_path)
        file_id = "local_#{team_name}_#{file_name.gsub(/[^a-zA-Z0-9]/, '_')}"

        {
          id: file_id,
          name: file_name,
          mime_type: "application/pdf",
          path: relative_path
        }
      end
    end
  end

  def download_file(file_id)
    if Rails.env.production?
      content_io = StringIO.new
      begin
        # Try direct download first
        @drive_service.get_file(file_id, download_dest: content_io)
      rescue Google::Apis::ClientError => e
        if e.status_code == 404
          log_error("Google Drive file not found", e, { file_id: file_id })
          raise ApiErrors::ResourceNotFoundError.new("File not found in Google Drive: #{file_id}")
        elsif is_export_required_error?(e)
          # If it's a Google Document, try to export it as PDF
          begin
            @drive_service.export_file(file_id, "application/pdf", download_dest: content_io)
          rescue Google::Apis::ClientError => export_error
            log_error("Google Drive export error", export_error, { file_id: file_id })
            raise ApiErrors::GoogleDriveError.new("Failed to export Google Drive file: #{export_error.message}")
          end
        else
          log_error("Google Drive download error", e, { file_id: file_id })
          raise ApiErrors::GoogleDriveError.new("Failed to download file: #{e.message}")
        end
      rescue Google::Apis::ServerError => e
        log_error("Google Drive server error", e, { file_id: file_id })
        raise ApiErrors::GoogleDriveError.new("Google Drive service error: #{e.message}")
      rescue Google::Apis::AuthorizationError => e
        log_error("Google Drive authorization error", e, { file_id: file_id })
        raise ApiErrors::GoogleDriveError.new("Google Drive authorization error: Please check your credentials")
      rescue => e
        log_error("Google Drive unexpected error", e, { file_id: file_id })
        raise ApiErrors::GoogleDriveError.new("Unexpected error accessing Google Drive: #{e.message}")
      end

      content_io.string
    else
      # For local testing, if it's a local file ID, read from the file system
      if file_id.start_with?("local_")
        # Parse the file path from the ID
        parts = file_id.split("_")
        team_name = parts[1]

        # The file name needs to be reconstructed with proper extension
        raw_file_name = parts[2..-1].join("_")

        # If the last part is 'pdf', treat it as an extension
        if raw_file_name.end_with?("_pdf")
          file_name = raw_file_name.gsub(/_pdf$/, ".pdf")
        else
          file_name = raw_file_name
        end

        Rails.logger.info("Looking for file: #{file_name} in team directory for #{team_name}")

        # Find matching files in the team directory
        team_directory = Rails.root.join("tmp/mock_drive", team_name)
        file_paths = Dir.glob(File.join(team_directory, "**", "*#{file_name}*"))

        if file_paths.empty?
          # Try a more permissive search if exact match fails
          file_paths = Dir.glob(File.join(team_directory, "**", "*.pdf"))
          Rails.logger.info("Fallback search found #{file_paths.count} PDF files in #{team_directory}")

          if file_paths.empty?
            raise ApiErrors::ResourceNotFoundError.new("Local file not found: #{file_id}")
          end
        end

        # Read the file content
        file_path = file_paths.first
        File.read(file_path)
      else
        # In development/test, return mock content based on file ID pattern for non-local files
        if file_id.include?("pdf")
          File.read(Rails.root.join("spec/fixtures/files/sample_project.pdf"))
        else
          "Sample content for file #{file_id}"
        end
      end
    end
  end

  private
  # Helper method to detect various Google Document export error messages
  def is_export_required_error?(error)
    return false unless error.is_a?(Google::Apis::ClientError)

    error_message = error.message.to_s.downcase

    # Check for various potential error messages related to export requirements
    error_message.include?("exportlinks") ||
    error_message.include?("export_links") ||
    error_message.include?("cannot download") ||
    error_message.include?("use export") ||
    error_message.include?("not downloadable") ||
    error_message.include?("google apps") ||
    error_message.include?("google-apps") ||
    error_message.include?("this document cannot be downloaded")
  end

  # Setup local test files for development/testing
  def setup_local_test_files
    mock_drive_dir = Rails.root.join("tmp/mock_drive")
    FileUtils.mkdir_p(mock_drive_dir)

    # Check if we already have team directories
    existing_teams = Dir.glob(File.join(mock_drive_dir, "*")).select { |f| File.directory?(f) }

    if existing_teams.any?
      Rails.logger.info("Using existing team directories in #{mock_drive_dir}")
      return
    end

    # Create team directories if none exist
    [ "TeamA", "TeamB", "TeamC" ].each do |team_name|
      team_dir = File.join(mock_drive_dir, team_name)
      FileUtils.mkdir_p(team_dir)

      # Create project directories
      [ "Project1", "Project2" ].each do |project_name|
        project_dir = File.join(team_dir, project_name)
        FileUtils.mkdir_p(project_dir)

        # Create sample PDF files
        2.times do |i|
          file_path = File.join(project_dir, "document_#{i+1}.pdf")
          next if File.exist?(file_path)

          # Create sample PDF content
          File.open(file_path, "w") do |f|
            f.puts "%PDF-1.5"
            f.puts "% #{team_name} - #{project_name} - Document #{i+1}"
            f.puts "This is a sample PDF file for #{team_name}'s #{project_name}."
            f.puts "It contains information about their hackathon project for testing purposes."
            f.puts "Team: #{team_name}"
            f.puts "Project: #{project_name}"
            f.puts "Document: #{i+1}"
            f.puts "Created for local AI testing without Google Drive"
          end
        end
      end
    end

    Rails.logger.info("Created local test files in #{mock_drive_dir}")
  end

  def authorize
    if Rails.env.production? || Rails.env.development?
      # Try to use environment variables first
      if ENV["GOOGLE_DRIVE_SERVICE_ACCOUNT_JSON"]
        # Service account authentication (recommended for backend)
        require "googleauth"

        # Use service account JSON from environment variable
        json_key_data = ENV["GOOGLE_DRIVE_SERVICE_ACCOUNT_JSON"]
        credentials = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: StringIO.new(json_key_data),
          scope: Google::Apis::DriveV3::AUTH_DRIVE_READONLY
        )
        credentials.fetch_access_token!
        credentials
      elsif ENV["GOOGLE_DRIVE_CREDENTIALS_PATH"] && File.exist?(ENV["GOOGLE_DRIVE_CREDENTIALS_PATH"])
        # Use service account JSON file from specified path
        require "googleauth"

        credentials = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: File.open(ENV["GOOGLE_DRIVE_CREDENTIALS_PATH"]),
          scope: Google::Apis::DriveV3::AUTH_DRIVE_READONLY
        )
        credentials.fetch_access_token!
        credentials
      elsif Rails.application.credentials.dig(:google_drive, :service_account)
        # Use credentials from Rails credentials system
        require "googleauth"

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
    log_error("Failed to authenticate with Google Drive API", e)
    nil # Return nil instead of raising to allow the app to start, but API requests will fail later
  end
end
