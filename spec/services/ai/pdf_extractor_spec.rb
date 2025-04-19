require 'rails_helper'

RSpec.describe Ai::PdfExtractor do
  let(:extractor) { described_class.new }
  let(:submission) { create(:submission, :pdf) }
  let(:google_drive_service) { instance_double(GoogleDriveService) }
  let(:pdf_content) { 'Sample PDF content for testing' }
  let(:mock_client) { instance_double(Ai::Client) }
  let(:pdf_summary) { "Summary of PDF document: This document details a technical approach to document processing with AI." }

  before do
    allow(Ai::Client).to receive(:new).and_return(mock_client)
    allow(google_drive_service).to receive(:download_file).with(submission.source_url).and_return(pdf_content)
    allow(mock_client).to receive(:generate_pdf_summary).with(pdf_content).and_return(pdf_summary)
  end

  describe '#process' do
    it 'downloads the PDF file from Google Drive' do
      expect(google_drive_service).to receive(:download_file).with(submission.source_url)
      extractor.process(submission, google_drive_service)
    end

    it 'generates a summary directly from the PDF content' do
      result = extractor.process(submission, google_drive_service)
      expect(result).to eq(pdf_summary)
    end

    context 'when PDF summarization fails in production' do
      before do
        # Set Rails environment to production for this test
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        allow(mock_client).to receive(:generate_pdf_summary).and_raise(StandardError.new('API error'))
      end

      it 'raises an error in production environment' do
        expect {
          extractor.process(submission, google_drive_service)
        }.to raise_error(StandardError, /API error/)
      end
    end
  end
end
