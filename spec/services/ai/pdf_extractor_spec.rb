require 'rails_helper'

RSpec.describe Ai::PdfExtractor do
  let(:extractor) { described_class.new }
  let(:submission) { create(:submission, :pdf) }
  let(:google_drive_service) { instance_double(GoogleDriveService) }
  let(:pdf_content) { 'Sample PDF content for testing' }
  let(:mock_client) { instance_double(Ai::Client) }

  before do
    allow(Ai::Client).to receive(:new).and_return(mock_client)
    allow(google_drive_service).to receive(:download_file).with(submission.source_url).and_return(pdf_content)
    allow(mock_client).to receive(:extract_text_from_document).and_return("Sample PDF content extracted from the document")
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
        allow(mock_client).to receive(:extract_text_from_document).and_return("Sample DOCX content extracted")
      end

      it 'extracts text from the DOCX file' do
        result = extractor.process(submission, google_drive_service)
        expect(result).to include('DOCX content')
      end
    end

    context 'when extraction fails in production' do
      before do
        # Set Rails environment to production for this test
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        allow(mock_client).to receive(:extract_text_from_document).and_raise(StandardError.new('API error'))
      end

      it 'raises an error in production environment' do
        expect {
          extractor.process(submission, google_drive_service)
        }.to raise_error(StandardError, /API error/)
      end
    end
  end
end
