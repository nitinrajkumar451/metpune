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

    def summarize_content(content, file_type, text = nil)
      # Skip API calls in development/test
      return mock_summary_response(file_type) unless Rails.env.production?

      # If we already have extracted text, use that instead of the raw content
      content_to_use = text.present? ? text : content

      case @provider
      when :claude
        call_claude_api(content_to_use, create_summary_prompt(file_type))
      when :openai
        call_openai_api(content_to_use, create_summary_prompt(file_type))
      else
        raise ArgumentError, "Unsupported AI provider: #{@provider}"
      end
    end

    def generate_team_summary(team_name, summaries)
      # Skip API calls in development/test
      return mock_team_summary(team_name) unless Rails.env.production?

      # Format the summaries as a string with project organization
      formatted_content = "Team: #{team_name}\n\n"

      # Group summaries by project
      summaries_by_project = summaries.group_by { |s| s[:project] }

      summaries_by_project.each do |project, project_summaries|
        formatted_content += "Project: #{project || 'Default'}\n"

        project_summaries.each do |summary|
          formatted_content += "File: #{summary[:filename]} (#{summary[:file_type]})\n"
          formatted_content += "Summary: #{summary[:summary]}\n\n"
        end

        formatted_content += "---\n\n"
      end

      case @provider
      when :claude
        call_claude_api(formatted_content, create_team_summary_prompt)
      when :openai
        call_openai_api(formatted_content, create_team_summary_prompt)
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

    def create_summary_prompt(file_type)
      case file_type
      when "pdf"
        "Please provide a concise summary of this PDF document, highlighting the key points, main arguments, and any important conclusions."
      when "docx"
        "Please provide a concise summary of this Word document, highlighting the key points, main arguments, and any important conclusions."
      when "pptx"
        "Please provide a concise executive summary of this presentation, highlighting the key messages and takeaways."
      when "jpg", "png"
        "Please provide a concise description and summary of what's shown in this image, including any relevant text or visual information."
      when "zip"
        "Please provide a concise summary of the collection of files extracted from this archive, highlighting the key information from each."
      else
        "Please provide a concise summary of this content, highlighting the key points and main takeaways."
      end
    end

    def create_team_summary_prompt
      <<~PROMPT
        I'll provide you with summaries of multiple documents submitted by a team for their project(s).
        Please analyze these summaries and create a comprehensive team report that includes:

        1. PRODUCT OBJECTIVE: What appears to be the main goal or product the team is working on
        2. WINS: Key achievements, successful implementations, or positive outcomes
        3. CHALLENGES: Difficulties, obstacles, or problems the team encountered
        4. INNOVATIONS: Unique approaches, creative solutions, or novel ideas
        5. TECHNICAL HIGHLIGHTS: Notable technical aspects, technologies used, or implementation details
        6. RECOMMENDATIONS: Constructive suggestions for improvement or future development
        7. OVERALL ASSESSMENT: A brief evaluation of the team's work as a whole

        Format your report with clear headings. Be specific and reference concrete details from the summaries.
        Focus on extracting meaningful insights rather than just repeating information.

        If some categories have little relevant information, it's okay to keep them brief or note the lack of data.
      PROMPT
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

    def mock_summary_response(file_type)
      case file_type
      when "pdf"
        "Summary of PDF document:\n\n" +
        "This document presents a research study on artificial intelligence applications in healthcare. " +
        "Key points include: (1) AI can improve diagnostic accuracy by 35%, (2) Implementation challenges " +
        "remain around data privacy and integration with existing systems, (3) The study recommends a " +
        "phased approach to AI adoption with proper training and governance frameworks."
      when "docx"
        "Summary of Word document:\n\n" +
        "This document outlines the strategic plan for Q3-Q4 2024. " +
        "The main objectives are: (1) Expand market reach in Asia-Pacific region, (2) Launch three new " +
        "product features based on customer feedback, (3) Improve customer retention by 15% through " +
        "enhanced support services. The document details resource allocation and success metrics for each initiative."
      when "pptx"
        "Executive summary of presentation:\n\n" +
        "This presentation provides an overview of the Metathon 2025 AI initiative. " +
        "The key takeaways are: (1) The AI document processing system shows 42% efficiency improvement " +
        "over manual methods, (2) Team collaboration features received positive feedback from 89% of users, " +
        "(3) Next steps include enhanced summarization capabilities and multi-language support."
      when "jpg", "png"
        "Summary of image content:\n\n" +
        "The image shows a data visualization dashboard with quarterly performance metrics. " +
        "Key information includes: (1) Revenue increased 23% year-over-year, (2) Customer acquisition cost " +
        "decreased by 12%, (3) Mobile usage surpassed desktop for the first time at 58% of total traffic. " +
        "The graph trends indicate consistent growth across all business segments."
      when "zip"
        "Summary of archive contents:\n\n" +
        "This archive contains a collection of project documents including: (1) Technical specifications " +
        "detailing API requirements and data models, (2) User research findings highlighting key pain points " +
        "and suggested improvements, (3) Design mockups for the new interface with a focus on accessibility, " +
        "(4) Implementation timeline with milestones and resource allocations."
      else
        "Content summary:\n\n" +
        "This content provides information about [generic topic]. Key points include important facts, " +
        "relevant data, and actionable insights that would be useful for understanding the subject matter."
      end
    end

    def mock_team_summary(team_name)
      <<~SUMMARY
        # Team #{team_name} - Comprehensive Report

        ## PRODUCT OBJECTIVE
        Based on the submitted documents, Team #{team_name} is developing an AI-powered document processing and analysis platform for the Metathon 2025 initiative. The system aims to streamline the ingestion, transcription, and summarization of various document types including PDFs, presentations, images, and archives.

        ## WINS
        - Successfully implemented document ingestion from Google Drive with 42% efficiency improvement over manual methods
        - Achieved high accuracy in text extraction across multiple file formats
        - Developed a robust API that provides both detailed content and concise summaries
        - Implemented project-based organization for improved team collaboration
        - Received positive feedback from 89% of test users on the system's usability

        ## CHALLENGES
        - Integration with existing systems required significant adaptation
        - Data privacy concerns needed to be addressed throughout development
        - Processing large ZIP archives and maintaining performance proved difficult
        - Handling multiple file types required specialized AI models and approaches

        ## INNOVATIONS
        - Created a multi-provider AI system that works with both Claude and OpenAI
        - Designed file type-specific prompts to generate more relevant summaries
        - Implemented a novel approach to ZIP archive processing that maintains context
        - Developed a hierarchical summarization system that works at file, project, and team levels

        ## TECHNICAL HIGHLIGHTS
        - Built on Rails 8.0.2 with PostgreSQL for robust data handling
        - Implemented background processing with Sidekiq for asynchronous document handling
        - Integrated with Google Drive API for seamless document access
        - Utilized advanced AI models for content extraction and summarization
        - Employed Test-Driven Development throughout the project

        ## RECOMMENDATIONS
        - Consider adding multi-language support for broader applicability
        - Implement additional security measures for handling sensitive documents
        - Explore real-time collaboration features to enhance team workflows
        - Add visualization tools for better data representation
        - Consider scaling infrastructure to handle larger document volumes

        ## OVERALL ASSESSMENT
        Team #{team_name} has delivered an impressive AI document processing system that effectively solves the challenges of document ingestion and analysis. The attention to both technical excellence and user experience is evident throughout their work. While there are opportunities for enhancement, the current implementation provides a solid foundation for future development.
      SUMMARY
    end
  end
end
