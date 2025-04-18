require "google/apis/drive_v3"

class GoogleDriveService
  def initialize
    @drive_service = Google::Apis::DriveV3::DriveService.new
    @drive_service.authorization = authorize
  end

  def list_team_folders
    # Find the Metathon2025 folder first
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
  end

  def list_team_files(team_name)
    # Find the Metathon2025 folder
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
  end

  def download_file(file_id)
    content_io = StringIO.new
    @drive_service.get_file!(file_id, download_dest: content_io)
    content_io.string
  end

  private

  def authorize
    # In a real application, you would use OAuth2 or service account credentials
    # For testing purposes, we'll return nil and handle the authentication in the tests
    # In production, you would implement proper Google Drive authentication
    nil
  end
end
