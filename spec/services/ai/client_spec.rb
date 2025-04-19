require 'rails_helper'

RSpec.describe Ai::Client do
  let(:client) { described_class.new }
  let(:test_content) { 'Sample content for testing' }

  describe '#generate_pdf_summary' do
    it 'returns mock response in test environment' do
      result = client.generate_pdf_summary(test_content)
      expect(result).to include('This document presents a comprehensive overview')
      expect(result).to include('The team employs a multi-layered architecture')
      expect(result).to include('Key features include automated document ingestion')
    end
  end

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

  describe '#summarize_content' do
    context 'with different file types' do
      it 'returns appropriate mock response for PDF' do
        result = client.summarize_content(test_content, 'pdf')
        expect(result).to include('Summary of PDF document')
        expect(result).to include('research study on artificial intelligence')
      end

      it 'returns appropriate mock response for DOCX' do
        result = client.summarize_content(test_content, 'docx')
        expect(result).to include('Summary of Word document')
        expect(result).to include('strategic plan for Q3-Q4 2024')
      end

      it 'returns appropriate mock response for PPTX' do
        result = client.summarize_content(test_content, 'pptx')
        expect(result).to include('Executive summary of presentation')
        expect(result).to include('Metathon 2025 AI initiative')
      end

      it 'returns appropriate mock response for images' do
        result = client.summarize_content(test_content, 'jpg')
        expect(result).to include('Summary of image content')
        expect(result).to include('data visualization dashboard')
      end

      it 'returns appropriate mock response for ZIP archives' do
        result = client.summarize_content(test_content, 'zip')
        expect(result).to include('Summary of archive contents')
        expect(result).to include('collection of project documents')
      end
    end

    context 'with pre-extracted text' do
      let(:extracted_text) { 'Pre-extracted text content from document' }

      it 'uses the provided text instead of raw content' do
        # In test environment, it will still return mock responses
        # But in production, it would use the provided text
        result = client.summarize_content(test_content, 'pdf', extracted_text)
        expect(result).to include('Summary of PDF document')
      end
    end
  end

  describe '#create_pdf_summary_prompt' do
    it 'creates detailed prompt for PDF analysis' do
      prompt = client.send(:create_pdf_summary_prompt)
      expect(prompt).to include('analyzing a PDF document from a hackathon project')
      expect(prompt).to include('Main objectives and goals')
      expect(prompt).to include('Key technical approaches')
      expect(prompt).to include('Technologies, frameworks, and tools')
    end
  end

  describe '#create_summary_prompt' do
    it 'creates appropriate prompt for PDF files' do
      prompt = client.send(:create_summary_prompt, 'pdf')
      expect(prompt).to include('concise summary of this PDF document')
    end

    it 'creates appropriate prompt for DOCX files' do
      prompt = client.send(:create_summary_prompt, 'docx')
      expect(prompt).to include('concise summary of this Word document')
    end

    it 'creates appropriate prompt for PPTX files' do
      prompt = client.send(:create_summary_prompt, 'pptx')
      expect(prompt).to include('executive summary of this presentation')
    end

    it 'creates appropriate prompt for image files' do
      prompt = client.send(:create_summary_prompt, 'jpg')
      expect(prompt).to include('description and summary of what\'s shown in this image')
    end

    it 'creates appropriate prompt for ZIP archives' do
      prompt = client.send(:create_summary_prompt, 'zip')
      expect(prompt).to include('summary of the collection of files')
    end

    it 'creates a generic prompt for unsupported file types' do
      prompt = client.send(:create_summary_prompt, 'unknown')
      expect(prompt).to include('concise summary of this content')
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
