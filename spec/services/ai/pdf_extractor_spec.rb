require 'rails_helper'

RSpec.describe Ai::PdfExtractor do
  let(:extractor) { described_class.new }
  let(:submission) { create(:submission, :pdf) }
  let(:google_drive_service) { instance_double(GoogleDriveService) }
  let(:pdf_content) { 'Sample PDF content for testing' }

  before do
    allow(google_drive_service).to receive(:download_file).with(submission.source_url).and_return(pdf_content)
    
    # Mock the HTTParty call to avoid actual network requests
    allow(HTTParty).to receive(:post).and_return(double('response', body: 'success'))
  end

  describe '#process' do
    it 'downloads the PDF file from Google Drive' do
      expect(google_drive_service).to receive(:download_file).with(submission.source_url)
      extractor.process(submission, google_drive_service)
    end

    it 'extracts text from the PDF' do
      result = extractor.process(submission, google_drive_service)
      expect(result).to include('Sample PDF content')
    end

    context 'with docx files' do
      let(:submission) { create(:submission, :docx) }
      let(:docx_content) { 'Sample DOCX content for testing' }

      before do
        allow(google_drive_service).to receive(:download_file).with(submission.source_url).and_return(docx_content)
      end

      it 'extracts text from the DOCX file' do
        result = extractor.process(submission, google_drive_service)
        expect(result).to include('Sample DOCX content')
      end
    end

    context 'when extraction fails' do
      before do
        allow(HTTParty).to receive(:post).and_raise(StandardError.new('API error'))
      end

      it 'raises an error' do
        expect {
          extractor.process(submission, google_drive_service)
        }.to raise_error(StandardError, /API error/)
      end
    end
  end
end
