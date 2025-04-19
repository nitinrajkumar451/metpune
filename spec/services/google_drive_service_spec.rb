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
    context 'in production environment' do
      let(:team_folders) do
        [
          Google::Apis::DriveV3::File.new(id: 'folder1', name: 'Team1', mime_type: 'application/vnd.google-apps.folder'),
          Google::Apis::DriveV3::File.new(id: 'folder2', name: 'Team2', mime_type: 'application/vnd.google-apps.folder'),
          Google::Apis::DriveV3::File.new(id: 'folder3', name: 'Team3', mime_type: 'application/vnd.google-apps.folder')
        ]
      end

      before do
        # Set Rails environment to production for this test
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

        # Mock metathon folder response
        allow(mock_drive_service).to receive(:list_files)
          .with(q: "name = 'Metathon2025' and mimeType = 'application/vnd.google-apps.folder'", fields: "files(id, name)")
          .and_return(instance_double(Google::Apis::DriveV3::FileList, files: [ Google::Apis::DriveV3::File.new(id: 'metathon_folder_id') ]))

        # Mock team folders response
        allow(mock_drive_service).to receive(:list_files)
          .with(q: "'metathon_folder_id' in parents and mimeType = 'application/vnd.google-apps.folder'", fields: "files(id, name)")
          .and_return(instance_double(Google::Apis::DriveV3::FileList, files: team_folders))
      end

      it 'returns a list of team names from Google Drive in production' do
        expect(service.list_team_folders).to eq([ 'Team1', 'Team2', 'Team3' ])
      end
    end

    context 'in development/test environment' do
      before do
        # Set Rails environment to development for this test
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      end

      it 'returns mock team names in development/test' do
        expect(service.list_team_folders).to eq([ 'Team1', 'Team2', 'Team3' ])
      end
    end
  end

  describe '#list_team_files' do
    let(:team_name) { 'Team1' }

    context 'in production environment' do
      let(:team_folder_id) { 'team_folder_id' }
      let(:team_folder_response) do
        instance_double(Google::Apis::DriveV3::FileList, files: [
          Google::Apis::DriveV3::File.new(id: team_folder_id, name: team_name, mime_type: 'application/vnd.google-apps.folder')
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
        # Set Rails environment to production for this test
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

        # First, find the metathon folder
        allow(mock_drive_service).to receive(:list_files)
          .with(q: "name = 'Metathon2025' and mimeType = 'application/vnd.google-apps.folder'", fields: "files(id, name)")
          .and_return(instance_double(Google::Apis::DriveV3::FileList, files: [ Google::Apis::DriveV3::File.new(id: 'metathon_parent_id') ]))

        # Next, find the team folder by name
        allow(mock_drive_service).to receive(:list_files)
          .with(q: "name = '#{team_name}' and mimeType = 'application/vnd.google-apps.folder' and 'metathon_parent_id' in parents", fields: "files(id, name, mimeType)")
          .and_return(team_folder_response)

        # Then, list files in that folder
        allow(mock_drive_service).to receive(:list_files)
          .with(q: "'#{team_folder_id}' in parents", fields: "files(id, name, mimeType)")
          .and_return(team_files_response)
      end

      it 'returns a list of files in the team folder in production' do
        expected_files = [
          { id: 'file1', name: 'document.pdf', mime_type: 'application/pdf', path: "Metathon2025/#{team_name}/document.pdf" },
          { id: 'file2', name: 'presentation.pptx', mime_type: 'application/vnd.openxmlformats-officedocument.presentationml.presentation', path: "Metathon2025/#{team_name}/presentation.pptx" },
          { id: 'file3', name: 'image.jpg', mime_type: 'image/jpeg', path: "Metathon2025/#{team_name}/image.jpg" }
        ]

        expect(service.list_team_files(team_name)).to eq(expected_files)
      end
    end

    context 'in development/test environment' do
      before do
        # Set Rails environment to development for this test
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      end

      it 'returns mock files with project folders in development/test' do
        files = service.list_team_files(team_name)

        # Verify we get the expected number of files
        expect(files.length).to eq(6)

        # Verify we have files from different projects
        expect(files.select { |f| f[:path].include?("Project1") }.length).to eq(3)
        expect(files.select { |f| f[:path].include?("Project2") }.length).to eq(2)
        expect(files.select { |f| f[:path].include?("SourceCode") }.length).to eq(1)

        # Verify file types
        expect(files.map { |f| f[:mime_type] }).to include(
          'application/pdf',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          'image/jpeg',
          'image/png',
          'application/zip'
        )
      end
    end
  end

  describe '#download_file' do
    let(:file_id) { 'file123' }

    context 'in production environment' do
      before do
        # Set Rails environment to production for this test
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

        allow(mock_drive_service).to receive(:get_file).and_return(mock_file)
        # Mock StringIO to capture content
        allow_any_instance_of(StringIO).to receive(:string).and_return('sample file content')
        # Make get_file return the StringIO and set its content
        allow(mock_drive_service).to receive(:get_file).with(file_id, download_dest: instance_of(StringIO)) do |_, options|
          options[:download_dest].write('sample file content')
          mock_file_content
        end
      end

      it 'downloads file content from Google Drive in production' do
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

        context 'with various export error messages' do
          # Test different error message variations that should trigger export
          [
            'Cannot download this file type directly, use export_links instead',
            'This file requires export, use exportLinks instead',
            'Use the export_links field to download this file',
            'Cannot download Google Apps files directly',
            'Not downloadable',
            'This is a Google-apps document and must be exported',
            'This document cannot be downloaded directly'
          ].each do |error_message|
            it "exports the file as PDF when direct download fails with message: '#{error_message}'" do
              allow(export_service).to receive(:get_file).with(file_id, download_dest: instance_of(StringIO))
                .and_raise(Google::Apis::ClientError.new(error_message))
              
              expect(export_service_instance.download_file(file_id)).to eq('sample file content')
            end
          end
        end
      end
    end

    context 'in development/test environment' do
      before do
        # Set Rails environment to development for this test
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      end

      it 'returns mock content based on file ID in development/test' do
        # Test PDF file
        expect(service.download_file('pdf_file')).to include('Sample document content')

        # Test PPTX file
        expect(service.download_file('pptx_file')).to include('Sample presentation content')

        # Test image file
        expect(service.download_file('jpg_file')).to include('Sample image binary data')

        # Test ZIP file
        expect(service.download_file('zip_file')).to include('Sample ZIP archive binary data')

        # Test generic file
        expect(service.download_file('random_file')).to include('Sample content for file')
      end
    end
  end
end
