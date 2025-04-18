require 'rails_helper'

RSpec.describe AI::PptxSummarizer do
  let(:summarizer) { described_class.new }
  let(:submission) { create(:submission, :pptx) }
  let(:google_drive_service) { instance_double(GoogleDriveService) }
  let(:pptx_content) { 'Sample PPTX content for testing' }
  
  before do
    allow(google_drive_service).to receive(:download_file).with(submission.source_url).and_return(pptx_content)
  end
  
  describe '#process' do
    it 'downloads the PPTX file from Google Drive' do
      expect(google_drive_service).to receive(:download_file).with(submission.source_url)
      summarizer.process(submission, google_drive_service)
    end
    
    it 'generates summaries for each slide' do
      result = summarizer.process(submission, google_drive_service)
      expect(result).to include('Slide summaries')
    end
    
    context 'when summarization fails' do
      before do
        allow(HTTParty).to receive(:post).and_raise(StandardError.new('API error'))
      end
      
      it 'raises an error' do
        expect {
          summarizer.process(submission, google_drive_service)
        }.to raise_error(StandardError, /API error/)
      end
    end
  end
end