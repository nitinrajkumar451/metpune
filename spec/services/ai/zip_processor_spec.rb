require 'rails_helper'

RSpec.describe AI::ZipProcessor do
  let(:processor) { described_class.new }
  let(:submission) { create(:submission, :zip) }
  let(:google_drive_service) { instance_double(GoogleDriveService) }
  let(:zip_content) { 'binary zip content' }

  before do
    allow(google_drive_service).to receive(:download_file).with(submission.source_url).and_return(zip_content)
  end

  describe '#process' do
    it 'downloads the ZIP file from Google Drive' do
      expect(google_drive_service).to receive(:download_file).with(submission.source_url)
      processor.process(submission, google_drive_service)
    end

    it 'extracts and processes files from the ZIP archive' do
      result = processor.process(submission, google_drive_service)
      expect(result).to include('Extracted ZIP contents')
    end

    context 'when ZIP processing fails' do
      before do
        allow_any_instance_of(Zip::File).to receive(:each).and_raise(StandardError.new('ZIP error'))
      end

      it 'raises an error' do
        expect {
          processor.process(submission, google_drive_service)
        }.to raise_error(StandardError, /ZIP error/)
      end
    end
  end
end
