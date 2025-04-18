require 'rails_helper'

RSpec.describe IngestDocumentsJob, type: :job do
  include ActiveJob::TestHelper
  
  describe '#perform' do
    let(:google_drive_service) { instance_double(GoogleDriveService) }
    let(:team_folder) { 'Team1' }
    let(:file_entries) do
      [
        { name: 'document.pdf', path: "Metathon2025/#{team_folder}/document.pdf", mime_type: 'application/pdf', id: '123' },
        { name: 'presentation.pptx', path: "Metathon2025/#{team_folder}/presentation.pptx", mime_type: 'application/vnd.openxmlformats-officedocument.presentationml.presentation', id: '456' },
        { name: 'image.jpg', path: "Metathon2025/#{team_folder}/image.jpg", mime_type: 'image/jpeg', id: '789' },
        { name: 'archive.zip', path: "Metathon2025/#{team_folder}/archive.zip", mime_type: 'application/zip', id: '101' },
        { name: 'unsupported.txt', path: "Metathon2025/#{team_folder}/unsupported.txt", mime_type: 'text/plain', id: '112' }
      ]
    end
    
    before do
      allow(GoogleDriveService).to receive(:new).and_return(google_drive_service)
      allow(google_drive_service).to receive(:list_team_folders).and_return([team_folder])
      allow(google_drive_service).to receive(:list_team_files).with(team_folder).and_return(file_entries)
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
    
    it 'enqueues processing jobs for each file type' do
      allow(AI::PdfExtractor).to receive(:new).and_return(double(process: 'PDF text'))
      allow(AI::PptxSummarizer).to receive(:new).and_return(double(process: 'PPT summary'))
      allow(AI::OcrExtractor).to receive(:new).and_return(double(process: 'OCR text'))
      allow(AI::ZipProcessor).to receive(:new).and_return(double(process: 'ZIP contents'))
      
      subject.perform
      
      expect(AI::PdfExtractor).to have_received(:new)
      expect(AI::PptxSummarizer).to have_received(:new)
      expect(AI::OcrExtractor).to have_received(:new)
      expect(AI::ZipProcessor).to have_received(:new)
    end
    
    it 'ignores unsupported file types' do
      expect {
        subject.perform
      }.not_to change { Submission.where(file_type: 'txt').count }
    end
    
    it 'updates submission status after processing' do
      allow(AI::PdfExtractor).to receive(:new).and_return(double(process: 'PDF text'))
      
      subject.perform
      
      pdf_submission = Submission.find_by(filename: 'document.pdf')
      expect(pdf_submission.status).to eq('success')
      expect(pdf_submission.raw_text).to eq('PDF text')
    end
    
    it 'marks submission as failed when processing errors occur' do
      allow(AI::PdfExtractor).to receive(:new).and_return(double(process: nil))
      allow(AI::PdfExtractor).to receive_message_chain(:new, :process).and_raise(StandardError.new('Processing failed'))
      
      subject.perform
      
      pdf_submission = Submission.find_by(filename: 'document.pdf')
      expect(pdf_submission.status).to eq('failed')
    end
  end
end