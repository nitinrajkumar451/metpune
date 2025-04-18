require 'rails_helper'

RSpec.describe Ai::OcrExtractor do
  let(:extractor) { described_class.new }
  let(:submission) { create(:submission, :jpg) }
  let(:google_drive_service) { instance_double(GoogleDriveService) }
  let(:image_content) { 'binary image content' }

  before do
    allow(google_drive_service).to receive(:download_file).with(submission.source_url).and_return(image_content)
    
    # Mock HTTParty to avoid actual network requests (for non-error tests)
    allow(HTTParty).to receive(:post).and_return(double('response', body: 'success'))
  end

  describe '#process' do
    it 'downloads the image file from Google Drive' do
      expect(google_drive_service).to receive(:download_file).with(submission.source_url)
      extractor.process(submission, google_drive_service)
    end

    it 'extracts text from the image using OCR' do
      result = extractor.process(submission, google_drive_service)
      expect(result).to include('OCR text')
    end

    context 'with PNG files' do
      let(:submission) { create(:submission, :png) }

      it 'extracts text from the PNG file' do
        result = extractor.process(submission, google_drive_service)
        expect(result).to include('OCR text')
      end
    end

    context 'when OCR fails' do
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
