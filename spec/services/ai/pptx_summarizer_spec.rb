require 'rails_helper'

RSpec.describe Ai::PptxSummarizer do
  let(:summarizer) { described_class.new }
  let(:submission) { create(:submission, :pptx) }
  let(:google_drive_service) { instance_double(GoogleDriveService) }
  let(:pptx_content) { 'Sample PPTX content for testing' }
  let(:mock_client) { instance_double(Ai::Client) }

  before do
    allow(Ai::Client).to receive(:new).and_return(mock_client)
    allow(google_drive_service).to receive(:download_file).with(submission.source_url).and_return(pptx_content)
    allow(mock_client).to receive(:summarize_presentation).and_return("Slide summaries from the presentation")
    allow(mock_client).to receive(:summarize_content).and_return("Executive summary of presentation: key concepts and takeaways")
  end

  describe '#process' do
    it 'downloads the PPTX file from Google Drive' do
      expect(google_drive_service).to receive(:download_file).with(submission.source_url)
      summarizer.process(submission, google_drive_service)
    end

    it 'generates slide-by-slide summaries and an executive summary' do
      result = summarizer.process(submission, google_drive_service)
      expect(result).to be_a(Hash)
      expect(result[:text]).to include('Slide summaries')
      expect(result[:summary]).to include('Executive summary of presentation')
    end

    context 'when summarization fails in production' do
      before do
        # Set Rails environment to production for this test
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        allow(mock_client).to receive(:summarize_presentation).and_raise(StandardError.new('API error'))
      end

      it 'raises an error in production environment' do
        expect {
          summarizer.process(submission, google_drive_service)
        }.to raise_error(StandardError, /API error/)
      end
    end
  end
end
