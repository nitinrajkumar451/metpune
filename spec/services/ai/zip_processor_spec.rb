require 'rails_helper'

RSpec.describe Ai::ZipProcessor do
  let(:processor) { described_class.new }
  let(:submission) { create(:submission, :zip) }
  let(:google_drive_service) { instance_double(GoogleDriveService) }
  let(:zip_content) { 'binary zip content' }

  before do
    allow(google_drive_service).to receive(:download_file).with(submission.source_url).and_return(zip_content)

    # Mock HTTParty to avoid actual network requests
    allow(HTTParty).to receive(:post).and_return(double('response', body: 'success'))
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

    context 'when ZIP processing fails in production' do
      before do
        # Set Rails environment to production for this test
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

        # Ensure the error is raised correctly in production
        allow(Zip::File).to receive(:open_buffer).and_raise(StandardError.new('API error'))
      end

      it 'raises an error in production environment' do
        expect {
          processor.process(submission, google_drive_service)
        }.to raise_error(StandardError, /API error/)
      end
    end
  end
end
