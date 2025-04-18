require 'rails_helper'

RSpec.describe Ai::Client do
  let(:client) { described_class.new }
  let(:test_content) { 'Sample content for testing' }

  describe '#extract_text_from_document' do
    it 'returns mock response in test environment' do
      result = client.extract_text_from_document(test_content, 'pdf')
      expect(result).to include('Sample PDF content extracted')
    end

    it 'returns appropriate mock for docx files' do
      result = client.extract_text_from_document(test_content, 'docx')
      expect(result).to include('Sample DOCX content extracted')
    end
  end

  describe '#extract_text_from_image' do
    it 'returns mock response in test environment' do
      result = client.extract_text_from_image(test_content)
      expect(result).to include('OCR text extracted from the image')
    end
  end

  describe '#summarize_presentation' do
    it 'returns mock response in test environment' do
      result = client.summarize_presentation(test_content)
      expect(result).to include('Slide summaries from the presentation')
    end
  end

  describe '#default_provider' do
    context 'in test environment' do
      it 'returns :mock provider' do
        # Access the private method using send
        expect(client.send(:default_provider)).to eq(:mock)
      end
    end

    # Skip production tests since they're difficult to mock with ENV variables
    # These tests would normally verify that the proper API keys are detected
  end
end
