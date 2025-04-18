require 'rails_helper'

RSpec.describe Ai::OcrExtractor do
  let(:extractor) { described_class.new }
  let(:submission) { create(:submission, :jpg) }
  let(:google_drive_service) { instance_double(GoogleDriveService) }
  let(:image_content) { 'binary image content' }
  let(:mock_client) { instance_double(Ai::Client) }

  before do
    allow(Ai::Client).to receive(:new).and_return(mock_client)
    allow(google_drive_service).to receive(:download_file).with(submission.source_url).and_return(image_content)
    allow(mock_client).to receive(:extract_text_from_image).and_return("OCR text extracted from the image")
    allow(mock_client).to receive(:summarize_content).and_return("Summary of image content: key visual elements and text")
  end

  describe '#process' do
    it 'downloads the image file from Google Drive' do
      expect(google_drive_service).to receive(:download_file).with(submission.source_url)
      extractor.process(submission, google_drive_service)
    end

    it 'extracts text and summary from the image using OCR' do
      result = extractor.process(submission, google_drive_service)
      expect(result).to be_a(Hash)
      expect(result[:text]).to include('OCR text')
      expect(result[:summary]).to include('Summary of image content')
    end

    context 'with PNG files' do
      let(:submission) { create(:submission, :png) }

      it 'extracts text and summary from the PNG file' do
        result = extractor.process(submission, google_drive_service)
        expect(result).to be_a(Hash)
        expect(result[:text]).to include('OCR text')
        expect(result[:summary]).to include('Summary of image content')
      end
    end

    context 'when OCR fails in production' do
      before do
        # Set Rails environment to production for this test
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        allow(mock_client).to receive(:extract_text_from_image).and_raise(StandardError.new('API error'))
      end

      it 'raises an error in production environment' do
        expect {
          extractor.process(submission, google_drive_service)
        }.to raise_error(StandardError, /API error/)
      end
    end
  end
end
