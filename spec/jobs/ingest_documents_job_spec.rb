require 'rails_helper'

RSpec.describe IngestDocumentsJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform' do
    let(:google_drive_service) { instance_double(GoogleDriveService) }
    let(:team_folder) { 'Team1' }
    let(:file_entries) do
      [
        # Project1 files
        { name: 'document.pdf', path: "Metathon2025/#{team_folder}/Project1/document.pdf", mime_type: 'application/pdf', id: '123' },
        { name: 'presentation.pptx', path: "Metathon2025/#{team_folder}/Project1/presentation.pptx", mime_type: 'application/vnd.openxmlformats-officedocument.presentationml.presentation', id: '456' },
        
        # Project2 files
        { name: 'image.jpg', path: "Metathon2025/#{team_folder}/Project2/image.jpg", mime_type: 'image/jpeg', id: '789' },
        { name: 'archive.zip', path: "Metathon2025/#{team_folder}/Project2/archive.zip", mime_type: 'application/zip', id: '101' },
        
        # Files without project folder (should default to "Default")
        { name: 'unsupported.txt', path: "Metathon2025/#{team_folder}/unsupported.txt", mime_type: 'text/plain', id: '112' }
      ]
    end

    before do
      allow(GoogleDriveService).to receive(:new).and_return(google_drive_service)
      allow(google_drive_service).to receive(:list_team_folders).and_return([ team_folder ])
      allow(google_drive_service).to receive(:list_team_files).with(team_folder).and_return(file_entries)
      
      # Mock download_file for all file types
      allow(google_drive_service).to receive(:download_file).and_return("file content")
      
      # Mock HTTParty for all AI service tests
      allow(HTTParty).to receive(:post).and_return(double('response', body: 'success'))
    end

    it 'fetches team folders from Google Drive' do
      expect(google_drive_service).to receive(:list_team_folders)
      subject.perform
    end

    it 'creates submissions for each supported file' do
      expect {
        subject.perform
      }.to change(Submission, :count).by(4) # 4 supported file types
    end
    
    it 'extracts project names from file paths correctly' do
      subject.perform
      
      # Check Project1 files
      pdf_submission = Submission.find_by(filename: 'document.pdf')
      expect(pdf_submission.project).to eq('Project1')
      
      pptx_submission = Submission.find_by(filename: 'presentation.pptx')
      expect(pptx_submission.project).to eq('Project1')
      
      # Check Project2 files
      jpg_submission = Submission.find_by(filename: 'image.jpg')
      expect(jpg_submission.project).to eq('Project2')
      
      zip_submission = Submission.find_by(filename: 'archive.zip')
      expect(zip_submission.project).to eq('Project2')
    end

    it 'enqueues processing jobs for each file type' do
      allow(Ai::PdfExtractor).to receive(:new).and_return(double(process: 'PDF text'))
      allow(Ai::PptxSummarizer).to receive(:new).and_return(double(process: 'PPT summary'))
      allow(Ai::OcrExtractor).to receive(:new).and_return(double(process: 'OCR text'))
      allow(Ai::ZipProcessor).to receive(:new).and_return(double(process: 'ZIP contents'))

      subject.perform

      expect(Ai::PdfExtractor).to have_received(:new)
      expect(Ai::PptxSummarizer).to have_received(:new)
      expect(Ai::OcrExtractor).to have_received(:new)
      expect(Ai::ZipProcessor).to have_received(:new)
    end

    it 'ignores unsupported file types' do
      expect {
        subject.perform
      }.not_to change { Submission.where(file_type: 'txt').count }
    end

    it 'updates submission status after processing' do
      allow(Ai::PdfExtractor).to receive(:new).and_return(double(process: 'PDF text'))

      subject.perform

      pdf_submission = Submission.find_by(filename: 'document.pdf')
      expect(pdf_submission.status).to eq('success')
      expect(pdf_submission.raw_text).to eq('PDF text')
    end

    it 'marks submission as failed when processing errors occur' do
      allow(Ai::PdfExtractor).to receive(:new).and_return(double(process: nil))
      allow(Ai::PdfExtractor).to receive_message_chain(:new, :process).and_raise(StandardError.new('Processing failed'))

      subject.perform

      pdf_submission = Submission.find_by(filename: 'document.pdf')
      expect(pdf_submission.status).to eq('failed')
    end
  end
end
