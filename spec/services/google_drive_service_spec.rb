require 'rails_helper'

RSpec.describe GoogleDriveService do
  let(:service) { described_class.new }
  let(:mock_drive_service) { instance_double(Google::Apis::DriveV3::DriveService) }
  let(:mock_response) { instance_double(Google::Apis::DriveV3::FileList) }
  let(:mock_file) { instance_double(Google::Apis::DriveV3::File) }
  let(:mock_file_content) { StringIO.new('sample file content') }

  before do
    allow(Google::Apis::DriveV3::DriveService).to receive(:new).and_return(mock_drive_service)
    allow(mock_drive_service).to receive(:authorization=)
  end

  describe '#list_team_folders' do
    let(:team_folders) do
      [
        Google::Apis::DriveV3::File.new(id: 'folder1', name: 'Team1', mime_type: 'application/vnd.google-apps.folder'),
        Google::Apis::DriveV3::File.new(id: 'folder2', name: 'Team2', mime_type: 'application/vnd.google-apps.folder'),
        Google::Apis::DriveV3::File.new(id: 'folder3', name: 'Team3', mime_type: 'application/vnd.google-apps.folder')
      ]
    end

    before do
      allow(mock_drive_service).to receive(:list_files).and_return(mock_response)
      allow(mock_response).to receive(:files).and_return(team_folders)
    end

    it 'returns a list of team names from Google Drive' do
      expect(service.list_team_folders).to eq([ 'Team1', 'Team2', 'Team3' ])
    end

    it 'uses the correct query to find folders in Metathon2025' do
      expected_query = "name = 'Metathon2025' and mimeType = 'application/vnd.google-apps.folder'"
      expect(mock_drive_service).to receive(:list_files).with(q: expected_query, fields: 'files(id, name)')
      service.list_team_folders
    end
  end

  describe '#list_team_files' do
    let(:team_folder_id) { 'team_folder_id' }
    let(:team_folder_response) do
      instance_double(Google::Apis::DriveV3::FileList, files: [
        Google::Apis::DriveV3::File.new(id: team_folder_id, name: 'Team1', mime_type: 'application/vnd.google-apps.folder')
      ])
    end

    let(:team_files) do
      [
        Google::Apis::DriveV3::File.new(id: 'file1', name: 'document.pdf', mime_type: 'application/pdf'),
        Google::Apis::DriveV3::File.new(id: 'file2', name: 'presentation.pptx', mime_type: 'application/vnd.openxmlformats-officedocument.presentationml.presentation'),
        Google::Apis::DriveV3::File.new(id: 'file3', name: 'image.jpg', mime_type: 'image/jpeg')
      ]
    end

    let(:team_files_response) do
      instance_double(Google::Apis::DriveV3::FileList, files: team_files)
    end

    before do
      # First, find the team folder by name
      allow(mock_drive_service).to receive(:list_files)
        .with(q: "name = 'Team1' and mimeType = 'application/vnd.google-apps.folder' and 'metathon_parent_id' in parents", fields: 'files(id, name, mimeType)')
        .and_return(team_folder_response)

      # Then, list files in that folder
      allow(mock_drive_service).to receive(:list_files)
        .with(q: "'#{team_folder_id}' in parents", fields: 'files(id, name, mimeType)')
        .and_return(team_files_response)

      # For finding metathon folder
      allow(mock_drive_service).to receive(:list_files)
        .with(q: "name = 'Metathon2025' and mimeType = 'application/vnd.google-apps.folder'", fields: 'files(id, name)')
        .and_return(instance_double(Google::Apis::DriveV3::FileList, files: [ Google::Apis::DriveV3::File.new(id: 'metathon_parent_id') ]))
    end

    it 'returns a list of files in the team folder' do
      expected_files = [
        { id: 'file1', name: 'document.pdf', mime_type: 'application/pdf', path: 'Metathon2025/Team1/document.pdf' },
        { id: 'file2', name: 'presentation.pptx', mime_type: 'application/vnd.openxmlformats-officedocument.presentationml.presentation', path: 'Metathon2025/Team1/presentation.pptx' },
        { id: 'file3', name: 'image.jpg', mime_type: 'image/jpeg', path: 'Metathon2025/Team1/image.jpg' }
      ]

      expect(service.list_team_files('Team1')).to eq(expected_files)
    end
  end

  describe '#download_file' do
    let(:file_id) { 'file123' }

    before do
      allow(mock_drive_service).to receive(:get_file).and_return(mock_file)
      # Mock StringIO to capture content
      allow_any_instance_of(StringIO).to receive(:string).and_return('sample file content')
      # Make get_file return the StringIO and set its content
      allow(mock_drive_service).to receive(:get_file).with(file_id, download_dest: instance_of(StringIO)) do |_, options|
        options[:download_dest].write('sample file content')
        mock_file_content
      end
    end

    it 'downloads file content from Google Drive' do
      content = service.download_file(file_id)
      expect(content).to eq('sample file content')
    end
    
    context 'when direct download fails' do
      let(:export_service) { instance_double(Google::Apis::DriveV3::DriveService) }
      let(:export_service_instance) { described_class.new }
      
      before do
        # Setup a new service instance for this context
        allow(Google::Apis::DriveV3::DriveService).to receive(:new).and_return(export_service)
        allow(export_service).to receive(:authorization=)
        
        # Setup the export_file mocks
        allow(export_service).to receive(:get_file).with(file_id, download_dest: instance_of(StringIO))
          .and_raise(Google::Apis::ClientError.new('Not downloadable'))
        
        allow(export_service).to receive(:export_file)
          .with(file_id, 'application/pdf', download_dest: instance_of(StringIO)) do |_, _, options|
            options[:download_dest].write('sample file content')
            mock_file_content
          end
      end
      
      it 'exports the file as PDF' do
        expect(export_service_instance.download_file(file_id)).to eq('sample file content')
      end
    end
  end
end
