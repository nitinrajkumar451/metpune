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

    def evaluate_team(team_name, team_summary, criteria)
      # Skip API calls in development/test
      return mock_team_evaluation(team_name, criteria) unless Rails.env.production?

      # Format the criteria as a string
      formatted_criteria = "Judging Criteria:\n\n"
      criteria.each do |criterion|
        formatted_criteria += "- #{criterion[:name]} (Weight: #{criterion[:weight]}): #{criterion[:description]}\n"
      end

      # Format the content for evaluation
      formatted_content = "Team: #{team_name}\n\n"
      formatted_content += "Team Summary:\n#{team_summary}\n\n"
      formatted_content += formatted_criteria

      case @provider
      when :claude
        call_claude_api(formatted_content, create_evaluation_prompt)
      when :openai
        call_openai_api(formatted_content, create_evaluation_prompt)
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

    def create_evaluation_prompt
      <<~PROMPT
        You're serving as an objective evaluator for a hackathon or project competition. I'll provide you with:

        1. A comprehensive summary of a team's submission
        2. A set of judging criteria with weighted importance

        Your task is to carefully evaluate the team based on the provided criteria. For each criterion:

        1. Assign a score from 1.0 to 5.0 (can use decimal points for precision)
           - 1.0-1.9: Poor - Significantly below expectations
           - 2.0-2.9: Fair - Below expectations
           - 3.0-3.9: Good - Meets expectations
           - 4.0-4.9: Excellent - Exceeds expectations
           - 5.0: Outstanding - Exceptionally exceeds expectations
        #{'   '}
        2. Provide specific, constructive feedback explaining your score

        3. Reference specific details from the team summary to justify your evaluation

        Finally, calculate a weighted total score and provide overall comments about the team's strengths and areas for improvement.

        Ensure your evaluation is:
        - Fair and objective
        - Based solely on the provided information
        - Specific and constructive
        - Balanced, highlighting both strengths and weaknesses

        Format your response as structured JSON with this exact format:
        {
          "scores": {
            "Criterion Name 1": {
              "score": <decimal score>,
              "weight": <weight from criteria>,
              "feedback": "<specific, detailed feedback>"
            },
            "Criterion Name 2": { ... },
            ...
          },
          "total_score": <calculated weighted average>,
          "comments": "<overall assessment with key strengths and improvement areas>"
        }
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

    def mock_team_evaluation(team_name, criteria)
      # Create a sample structured response based on the criteria
      scores = {}
      total_weighted_score = 0
      total_weight = 0

      criteria.each do |criterion|
        name = criterion[:name]
        weight = criterion[:weight].to_f

        # Generate a sample score between 3.5 and 4.8
        score = (3.5 + rand * 1.3).round(1)

        scores[name] = {
          "score" => score,
          "weight" => weight,
          "feedback" => "Team #{team_name} #{score >= 4.0 ? 'excelled in' : 'performed well on'} the #{name.downcase} criterion. #{mock_feedback_for_criterion(name, score)}"
        }

        total_weighted_score += score * weight
        total_weight += weight
      end

      average_score = (total_weighted_score / total_weight).round(2)

      # Format the response as JSON
      JSON.generate({
        "scores" => scores,
        "total_score" => average_score,
        "comments" => "Team #{team_name} achieved an overall score of #{average_score}/5.0, demonstrating #{average_score >= 4.5 ? 'outstanding' : average_score >= 4.0 ? 'excellent' : average_score >= 3.5 ? 'strong' : 'solid'} performance across evaluation criteria. #{mock_overall_feedback(average_score)}"
      })
    end

    def mock_feedback_for_criterion(criterion_name, score)
      case criterion_name.downcase
      when /innovat/
        if score >= 4.5
          "Their solution demonstrates exceptional creativity and novel approaches to solving problems."
        elsif score >= 4.0
          "They showed excellent innovation in several aspects of their project implementation."
        else
          "They incorporated some innovative elements in their approach."
        end
      when /tech/
        if score >= 4.5
          "The technical implementation is outstanding, with excellent architecture and code quality."
        elsif score >= 4.0
          "The technical execution shows strong engineering principles and good attention to detail."
        else
          "The technical implementation is solid with some notable highlights."
        end
      when /impact/
        if score >= 4.5
          "The potential impact of this solution is substantial, addressing critical needs with a scalable approach."
        elsif score >= 4.0
          "This project has significant potential impact in its target domain."
        else
          "The solution shows promise for making a positive impact in its field."
        end
      when /present/
        if score >= 4.5
          "The presentation of their work is exceptionally clear, engaging, and well-structured."
        elsif score >= 4.0
          "They presented their work effectively with good clarity and organization."
        else
          "The presentation communicates the key points adequately."
        end
      when /complete/
        if score >= 4.5
          "The project is remarkably complete with all planned features implemented to a high standard."
        elsif score >= 4.0
          "The implementation is quite comprehensive with most features fully realized."
        else
          "Most core features are implemented, though some areas could be further developed."
        end
      else
        if score >= 4.5
          "Outstanding performance in this area."
        elsif score >= 4.0
          "Excellent work in this criterion."
        else
          "Good performance with room for enhancement."
        end
      end
    end

    def mock_overall_feedback(average_score)
      if average_score >= 4.5
        "Particularly impressive aspects include their technical implementation and innovative approach. With some minor enhancements to user experience and documentation, this project could have even greater impact."
      elsif average_score >= 4.0
        "The team demonstrated strong technical skills and good problem-solving capabilities. Further refinement of the user interface and expanded feature set would strengthen future iterations."
      elsif average_score >= 3.5
        "The team shows solid understanding of the problem domain and has created a functional solution. Areas for improvement include technical robustness, feature completeness, and presentation clarity."
      else
        "While the core concept shows promise, the team would benefit from addressing implementation quality, feature completeness, and better articulating the project's impact."
      end
    end
  end
end
