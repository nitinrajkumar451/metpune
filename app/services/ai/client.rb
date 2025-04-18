module Ai
  class Client
    def initialize(provider = nil)
      @provider = provider || default_provider
    end

    def extract_text_from_document(content, file_type)
      # Skip API calls in development/test
      return mock_document_response(file_type) unless Rails.env.production?

      case @provider
      when :claude
        call_claude_api(content, create_document_prompt(file_type))
      when :openai
        call_openai_api(content, create_document_prompt(file_type))
      else
        raise ArgumentError, "Unsupported AI provider: #{@provider}"
      end
    end

    def extract_text_from_image(content)
      # Skip API calls in development/test
      return mock_image_response unless Rails.env.production?

      case @provider
      when :claude
        call_claude_api(content, create_image_prompt)
      when :openai
        call_openai_api(content, create_image_prompt)
      else
        raise ArgumentError, "Unsupported AI provider: #{@provider}"
      end
    end

    def summarize_presentation(content)
      # Skip API calls in development/test
      return mock_presentation_response unless Rails.env.production?

      case @provider
      when :claude
        call_claude_api(content, create_presentation_prompt)
      when :openai
        call_openai_api(content, create_presentation_prompt)
      else
        raise ArgumentError, "Unsupported AI provider: #{@provider}"
      end
    end

    private

    def default_provider
      return :mock unless Rails.env.production?

      # Determine provider based on environment variables
      if ENV["CLAUDE_API_KEY"].present?
        :claude
      elsif ENV["OPENAI_API_KEY"].present?
        :openai
      else
        # Only raise in production, use mock provider in other environments
        if Rails.env.production?
          raise "No AI provider credentials found. Set CLAUDE_API_KEY or OPENAI_API_KEY environment variables."
        else
          :mock
        end
      end
    end

    def call_claude_api(content, prompt)
      api_key = ENV["CLAUDE_API_KEY"]
      raise "CLAUDE_API_KEY environment variable not set" if api_key.blank?

      # Use Base64 encoding for binary content
      content_base64 = Base64.strict_encode64(content) if content.is_a?(String)

      response = HTTParty.post(
        "https://api.anthropic.com/v1/messages",
        headers: {
          "Content-Type" => "application/json",
          "x-api-key" => api_key,
          "anthropic-version" => "2023-06-01"
        },
        body: {
          model: "claude-3-opus-20240229",
          max_tokens: 4000,
          messages: [
            {
              role: "user",
              content: [
                {
                  type: "text",
                  text: prompt
                },
                content.is_a?(String) ? {
                  type: "image",
                  source: {
                    type: "base64",
                    media_type: determine_media_type(content),
                    data: content_base64
                  }
                } : nil
              ].compact
            }
          ]
        }.to_json
      )

      unless response.success?
        Rails.logger.error("Claude API error: #{response.code} - #{response.body}")
        raise "Claude API error: #{response.code}"
      end

      # Extract the response content from Claude API
      JSON.parse(response.body).dig("content", 0, "text")
    end

    def call_openai_api(content, prompt)
      api_key = ENV["OPENAI_API_KEY"]
      raise "OPENAI_API_KEY environment variable not set" if api_key.blank?

      # Use Base64 encoding for binary content
      content_base64 = Base64.strict_encode64(content) if content.is_a?(String)

      response = HTTParty.post(
        "https://api.openai.com/v1/chat/completions",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{api_key}"
        },
        body: {
          model: "gpt-4-vision-preview",
          max_tokens: 4000,
          messages: [
            {
              role: "user",
              content: [
                {
                  type: "text",
                  text: prompt
                },
                content.is_a?(String) ? {
                  type: "image_url",
                  image_url: {
                    url: "data:#{determine_media_type(content)};base64,#{content_base64}"
                  }
                } : nil
              ].compact
            }
          ]
        }.to_json
      )

      unless response.success?
        Rails.logger.error("OpenAI API error: #{response.code} - #{response.body}")
        raise "OpenAI API error: #{response.code}"
      end

      # Extract the response content from OpenAI API
      JSON.parse(response.body).dig("choices", 0, "message", "content")
    end

    def determine_media_type(content)
      # Try to determine the media type from the binary content
      # This is a simplified implementation - in a real app, you would use a more robust method
      if content.start_with?("%PDF")
        "application/pdf"
      elsif content.start_with?("\x89PNG")
        "image/png"
      elsif content.start_with?("\xFF\xD8\xFF")
        "image/jpeg"
      else
        "application/octet-stream"
      end
    end

    def create_document_prompt(file_type)
      case file_type
      when "pdf"
        "Please extract all the text content from this PDF document. Maintain the structure and formatting as much as possible."
      when "docx"
        "Please extract all the text content from this Word document. Maintain the structure and formatting as much as possible."
      else
        "Please extract all the text content from this document."
      end
    end

    def create_image_prompt
      "Please extract and transcribe all text visible in this image. Organize it in a logical reading order."
    end

    def create_presentation_prompt
      "Please provide a slide-by-slide summary of this presentation. For each slide, include the main points, key information, and any important data."
    end

    # Mock responses for testing
    def mock_document_response(file_type)
      if file_type == "pdf"
        "Sample PDF content extracted from the document.\n\nThis is a mock extraction for testing purposes.\n\nContent appears to be a technical document with several sections including introduction, methodology, and results."
      else # docx
        "Sample DOCX content extracted from the document.\n\nThis is a mock extraction for testing purposes.\n\nDocument includes formatting like tables, bullet points, and embedded images which have been converted to plain text."
      end
    end

    def mock_image_response
      "OCR text extracted from the image:\n\n" +
      "This is a sample text that would be extracted from an image using OCR technology.\n" +
      "In a real application, this would contain the actual text content from the image."
    end

    def mock_presentation_response
      "Slide summaries from the presentation:\n\n" +
      "Slide 1: Introduction to the project\n" +
      "Slide 2: Key features and architecture\n" +
      "Slide 3: Technical implementation details\n" +
      "Slide 4: Results and metrics\n" +
      "Slide 5: Future enhancements and roadmap"
    end
  end
end
