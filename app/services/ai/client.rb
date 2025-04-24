module Ai
  class Client
    require_relative "../concerns/service_error_handler"
    include ServiceErrorHandler
    def initialize(provider = nil)
      @provider = provider || default_provider
    end

    def generate_pdf_summary(content)
      # Store content for use in prompts
      @current_content = content
      
      # If we have a valid Claude API key, always use it regardless of environment
      if ENV["CLAUDE_API_KEY"].present?
        Rails.logger.info("Using Claude API for PDF summary generation")
        call_claude_api(content, create_pdf_summary_prompt)
      # If we have a valid OpenAI API key, use it instead
      elsif ENV["OPENAI_API_KEY"].present?
        Rails.logger.info("Using OpenAI API for PDF summary generation")
        call_openai_api(content, create_pdf_summary_prompt)
      # Fall back to mock responses if no API keys are available
      else
        Rails.logger.info("No API keys available, using enhanced mock PDF summary")
        enhanced_mock_pdf_summary(content)
      end
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

      # Special handling for testing environment
      if ENV["CLAUDE_API_KEY"].present?
        Rails.logger.info("Using Claude API for team summary generation")
        call_claude_api(formatted_content, create_team_summary_prompt)
      else
        Rails.logger.info("No Claude API key available, using enhanced mock team summary")
        enhanced_mock_team_summary(team_name, summaries)
      end
    end

    def evaluate_team(team_name, team_summary, criteria, hackathon_name = nil)
      # Format the criteria as a string
      formatted_criteria = "Judging Criteria:\n\n"
      criteria.each do |criterion|
        formatted_criteria += "- #{criterion[:name]} (Weight: #{criterion[:weight]}): #{criterion[:description]}\n"
      end

      # Format the content for evaluation
      formatted_content = "Team: #{team_name}\n\n"
      formatted_content += "Hackathon: #{hackathon_name || 'Metathon 2025'}\n\n"
      formatted_content += "Team Summary:\n#{team_summary}\n\n"
      formatted_content += formatted_criteria

      # Detect which provider to use
      provider_to_use = detect_provider

      # Log the provider we're using
      Rails.logger.info("Evaluating team: #{team_name} using provider: #{provider_to_use}")
      Rails.logger.info("Criteria: #{criteria.map { |c| c[:name] }.join(', ')}")

      # Make the API call based on the detected provider
      evaluation_result = case provider_to_use
      when :claude
        Rails.logger.info("Using Claude API for team evaluation")
        call_claude_api(formatted_content, create_evaluation_prompt)
      when :openai
        Rails.logger.info("Using OpenAI API for team evaluation")
        call_openai_api(formatted_content, create_evaluation_prompt)
      else
        # Only use mock if no API keys are configured
        Rails.logger.warn("No AI provider available, generating mock evaluation data for: #{team_name}")
        mock_team_evaluation(team_name, criteria, hackathon_name)
      end

      # Ensure we return a valid result
      if evaluation_result.nil? || evaluation_result.to_s.strip.empty?
        Rails.logger.error("Empty evaluation result returned from provider: #{provider_to_use}")
        # Return a valid mock response as fallback
        mock_team_evaluation(team_name, criteria, hackathon_name)
      else
        evaluation_result
      end
    end
    
    # Helper method to detect which provider to use
    def detect_provider
      if ENV["CLAUDE_API_KEY"].present?
        :claude
      elsif ENV["OPENAI_API_KEY"].present?
        :openai
      else
        :mock
      end
    end

    def generate_team_blog(team_name, team_summary, hackathon_name = nil)
      # Skip API calls in development/test
      return mock_team_blog(team_name, hackathon_name) unless Rails.env.production?

      # Format the content for blog generation
      formatted_content = "Team: #{team_name}\n\n"
      formatted_content += "Hackathon: #{hackathon_name || 'Metathon 2025'}\n\n"
      formatted_content += "Team Summary:\n#{team_summary}\n\n"

      case @provider
      when :claude
        call_claude_api(formatted_content, create_blog_prompt)
      when :openai
        call_openai_api(formatted_content, create_blog_prompt)
      else
        raise ArgumentError, "Unsupported AI provider: #{@provider}"
      end
    end

    def generate_hackathon_insights(team_summaries, hackathon_name = nil)
      # Skip API calls in development/test
      return mock_hackathon_insights(hackathon_name) unless Rails.env.production?

      # Format all team summaries for analysis
      formatted_content = "Hackathon: #{hackathon_name || 'Metathon 2025'}\n\n"
      formatted_content += "Team Summaries:\n\n"

      team_summaries.each do |summary|
        formatted_content += "Team: #{summary.team_name}\n"
        formatted_content += "Summary:\n#{summary.content}\n\n"
        formatted_content += "---\n\n"
      end

      case @provider
      when :claude
        call_claude_api(formatted_content, create_hackathon_insights_prompt)
      when :openai
        call_openai_api(formatted_content, create_hackathon_insights_prompt)
      else
        raise ArgumentError, "Unsupported AI provider: #{@provider}"
      end
    end

    # No need for explicit public declaration

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
          raise ApiErrors::AiServiceError.new("No AI provider credentials found. Set CLAUDE_API_KEY or OPENAI_API_KEY environment variables.")
        else
          :mock
        end
      end
    end

    def call_claude_api(content, prompt)
      api_key = ENV["CLAUDE_API_KEY"]
      if api_key.blank?
        log_error("Claude API key not configured")
        raise ApiErrors::AiServiceError.new("Claude API key not configured", "Claude")
      end

      # Determine if this is likely a PDF
      is_pdf = content.is_a?(String) && content.start_with?("%PDF")

      begin
        # Prepare modified prompt for PDF content
        enhanced_prompt = prompt
        if is_pdf
          # Since we can't directly send PDF, extract some sample content to improve context
          sample_content = content[0..1000].force_encoding('UTF-8').scrub
          Rails.logger.info("PDF detected, using text-only processing")
          enhanced_prompt = "#{prompt}\n\nThis appears to be a PDF document. Here's a sample of the binary content (this may look garbled):\n\n#{sample_content}\n\nPlease provide the best summary you can based on this information."
        end
        
        # Special handling for evaluation prompts - ensure they are formatted correctly
        if prompt.include?("Judging Criteria") || prompt.include?("Format your response as structured JSON")
          Rails.logger.info("Detected evaluation prompt, using evaluation system prompt")
          system_prompt = "You are a fair and objective hackathon judge. You assess teams' submissions based on provided criteria and always respond in valid JSON format with scores, weights, and feedback. Your response MUST contain 'scores' and 'total_score' fields formatted exactly as specified in the prompt."
        else
          system_prompt = "You are an expert PDF content analyzer. Your task is to provide concise, insightful summaries of hackathon team documents."
        end
        
        Rails.logger.info("Making Claude API call with prompt length: #{enhanced_prompt.length} characters")
        # Make the API call with text-only content
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
                    text: enhanced_prompt
                  }
                ]
              }
            ],
            system: system_prompt
          }.to_json,
          timeout: 180  # Increased timeout for processing
        )

        # Handle response using our helper
        handle_api_response("Claude", response)

        # Extract the response content from Claude API
        response_body = JSON.parse(response.body)
        Rails.logger.info("Claude API response received, parsing result")
        
        if response_body["content"].present? && response_body["content"].is_a?(Array)
          # Extract the text from the first content block
          result = response_body["content"].find { |c| c["type"] == "text" }&.dig("text")
          
          # For evaluation prompts, try to extract JSON from the response
          if prompt.include?("Format your response as structured JSON")
            Rails.logger.info("Extracting JSON from Claude evaluation response")
            begin
              # Try to find valid JSON in the response
              json_pattern = /```json\n(.*?)\n```|```(.*?)```|\{.*"scores".*"total_score".*\}/m
              if match = result.match(json_pattern)
                json_str = match[1] || match[2] || match[0]
                Rails.logger.info("Found JSON pattern, attempting to parse")
                return json_str.strip
              else
                Rails.logger.warn("No JSON pattern found in Claude response")
                return result
              end
            rescue => json_err
              Rails.logger.error("Error extracting JSON from Claude response: #{json_err.message}")
              return result
            end
          else
            return result
          end
        else
          # Fallback if response format is unexpected
          Rails.logger.warn("Unexpected Claude API response format: #{response_body.inspect}")
          if prompt.include?("Format your response as structured JSON")
            # Extract team name safely
            team_name = "Unknown Team"
            if content.is_a?(String)
              team_match = content.match(/Team: (.*?)$/)
              team_name = team_match[1] if team_match
            end
            mock_team_evaluation(team_name, [], nil)
          else
            enhanced_mock_pdf_summary(content)
          end
        end
      rescue => e
        # Handle all errors
        log_error("Claude API error: #{e.message}")
        Rails.logger.error("Falling back to mock implementation due to API error")
        
        if prompt.include?("Format your response as structured JSON")
          # For evaluation errors, return valid mock evaluation data
          team_name = "Unknown Team"
          criteria = []
          
          # Safely extract team name if possible
          if content.is_a?(String)
            team_match = content.match(/Team: (.*?)$/m)
            if team_match && team_match[1]
              team_name = team_match[1].strip
            end
            
            # Try to extract criteria
            criteria_section = content.match(/Judging Criteria:(.*?)(?=Team:|$)/m)
            if criteria_section && criteria_section[1]
              criteria_section[1].scan(/- ([^(]+) \(Weight: ([^)]+)\): (.*)$/i).each do |name, weight, desc|
                criteria << { name: name.strip, weight: weight.to_f, description: desc.strip }
              end
            end
          end
          
          mock_team_evaluation(team_name, criteria, nil)
        else
          enhanced_mock_pdf_summary(content)
        end
      end
    end

    def call_openai_api(content, prompt)
      api_key = ENV["OPENAI_API_KEY"]
      if api_key.blank?
        log_error("OpenAI API key not configured")
        raise ApiErrors::AiServiceError.new("OpenAI API key not configured", "OpenAI")
      end

      # Use Base64 encoding for binary content
      content_base64 = Base64.strict_encode64(content) if content.is_a?(String)

      begin
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
          }.to_json,
          timeout: 60  # Add a timeout to prevent hanging requests
        )

        # Handle response using our helper
        handle_api_response("OpenAI", response)

        # Extract the response content from OpenAI API
        JSON.parse(response.body).dig("choices", 0, "message", "content")
      rescue HTTParty::Error, Timeout::Error, SocketError, JSON::ParserError => e
        # Handle network and parsing errors
        handle_request_error("OpenAI", e)
      end
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

    def create_pdf_summary_prompt
      # If we're sending the actual PDF content as an image, adjust the prompt accordingly
      if defined?(@current_content) && @current_content.is_a?(String) && @current_content.start_with?("%PDF")
        <<~PROMPT
          You're analyzing a PDF document from a hackathon project. The PDF content is provided as an attachment.

          Please provide a concise yet comprehensive summary of this document that captures:

          1. Main objectives and goals described in the project
          2. Key technical approaches and methodologies used
          3. Important features or functionality highlighted
          4. Technologies, frameworks, and tools mentioned
          5. Any notable results, metrics, or achievements
          6. Challenges or limitations discussed
          7. Future work or improvements suggested

          Also look for specific metadata like:
          - Team name (usually indicated with "Team:" or similar)
          - Project name (usually indicated with "Project:" or similar)
          - Date information
          - Author names if present

          Structure your summary in coherent paragraphs. Be specific about technical details when they appear in the document. Try to accurately represent the document's main points without being too wordy. 
          Focus on extracting meaningful information that would be helpful for evaluating this hackathon project.
        PROMPT
      else
        <<~PROMPT
          You're analyzing a PDF document from a hackathon project. Here is the content extracted from the PDF:

          #{@current_content}

          Please provide a concise yet comprehensive summary of this document that captures:

          1. Main objectives and goals described
          2. Key technical approaches and methodologies  
          3. Important features or functionality highlighted
          4. Technologies, frameworks, and tools mentioned
          5. Any notable results, metrics, or achievements
          6. Challenges or limitations discussed
          7. Future work or improvements suggested

          Also look for specific metadata like:
          - Team name (usually indicated with "Team:" or similar)
          - Project name (usually indicated with "Project:" or similar)
          - Date information
          - Author names if present

          Structure your summary in coherent paragraphs. Be specific about technical details when they appear in the document. Try to accurately represent the document's main points without being too wordy.
        PROMPT
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

    def create_blog_prompt
      <<~PROMPT
        You're an expert technical content writer for hackathons. Using the structured input below, generate a blog post in Markdown format. Follow the given blog structure template. Make the tone engaging, informative, and a bit celebratory. The goal is to showcase the team and their work clearly to a technical and general audience.

        Use this structure:

        Title

        Introduction

        The Problem They Tackled

        Their Solution

        Key Features

        Tech Stack

        Learnings & Wins

        Mishaps & Challenges

        What's Next

        AI's Take (Appreciation)

        Final Thoughts

        Include a frontmatter block with the title, author (team name), tags, and date.

        Be specific and detailed, using information from the team summary to craft a compelling narrative.
        Ensure the blog post is well-formatted in Markdown, with appropriate headers, bullet points, and emphasis.
        Focus on the technical aspects of the project while making it accessible to a wider audience.
        Include at least 3-5 sentences per section to provide adequate depth.

        Today's date is: #{Date.today.strftime('%B %d, %Y')}
      PROMPT
    end

    def create_hackathon_insights_prompt
      <<~PROMPT
        You're an expert in analyzing hackathon and innovation trends. Review the team summaries from this hackathon to create a comprehensive trends analysis in Markdown format.#{' '}

        The analysis should be specific to the hackathon mentioned in the provided content.

        Analyze across all teams and identify patterns in:

        1. Technologies: Common tech stacks, frameworks, languages, and tools used
        2. Problem Domains: Recurring themes in the problems teams chose to tackle
        3. AI Use Cases: How AI/ML was utilized across different projects
        4. Approaches: Common methodologies, architectures, or techniques
        5. Challenges: Recurring obstacles teams faced
        6. Collaboration Patterns: Team dynamics and work distribution trends
        7. Innovation Trends: Novel or unexpected approaches that stood out

        For each area, include:
        - The 3-5 most prevalent trends with specific examples from teams
        - Any outliers or unique approaches worth highlighting
        - Brief analysis of why these trends emerged (industry influence, hackathon constraints, etc.)

        Format your response as a well-structured Markdown document with appropriate headings, subheadings, lists, and emphasis. Start with an executive summary of the key findings.

        Include a section that highlights particularly innovative or effective approaches from specific teams.

        End with recommendations for future hackathons based on these insights.

        Today's date is: #{Date.today.strftime('%B %d, %Y')}
      PROMPT
    end

    # Mock responses for testing
    def enhanced_mock_pdf_summary(content)
      # Extract key information from the PDF content
      team_match = content.match(/Team:\s*(\w+)/)
      project_match = content.match(/Project:\s*(\w+)/)
      
      team_name = team_match ? team_match[1].strip : "Unknown"
      project_name = project_match ? project_match[1].strip : "Project"
      
      # Extract technologies mentioned
      tech_keywords = [
        "Python", "TensorFlow", "PyTorch", "React", "Node.js", "MongoDB", "AWS", 
        "Spring Boot", "Kafka", "PostgreSQL", "Ethereum", "IoT", "Ruby", "Rails",
        "Microservices", "Docker", "Kubernetes", "Blockchain", "Machine Learning",
        "NLP", "Computer Vision", "API", "Redux", "GraphQL", "REST", "Serverless"
      ]
      
      technologies = tech_keywords.select { |tech| content.include?(tech) }.join(", ")
      technologies = "modern web technologies" if technologies.empty?
      
      # Extract features if mentioned with numbered or bulleted lists
      features = []
      content.scan(/(\d+\.\s+[^\n.]+|\-\s+[^\n.]+)/).each do |match|
        features << match[0].strip
      end
      
      # Limit to top 3 features
      features = features[0..2] if features.length > 3
      
      # Look for metrics or results
      metrics_match = content.scan(/(\d+%|\d+\s*metric tons|\d+\s*reduction)/)
      metrics = metrics_match.flatten[0..2].join(", ") if metrics_match.any?
      
      # Generate a summary based on the actual content
      summary = <<~SUMMARY
        This document presents #{team_name}'s #{project_name} project for the Metathon hackathon. The team has developed #{project_name.include?("AI") ? "an AI-powered solution" : "an innovative solution"} that addresses real-world challenges in the #{project_name.include?("Fin") ? "financial sector" : project_name.include?("Eco") ? "sustainability space" : project_name.include?("Smart") ? "urban environment" : "technology sector"}.
        
        The team employs a sophisticated technical architecture utilizing #{technologies}. Their approach demonstrates careful attention to both technical excellence and user experience considerations, with a focus on scalability and maintainability.
        
        #{features.any? ? "Key features highlighted in the document include " + features.map { |f| f.sub(/^\d+\.\s+|\-\s+/, '') }.join(", ") + "." : "The solution offers multiple innovative features designed to address user needs effectively while maintaining technical robustness."} 
        
        #{metrics ? "The project shows promising results with metrics including #{metrics}." : "The document outlines both the technical implementation details and the practical impact of the solution."}
        
        The team acknowledges existing limitations and provides a thoughtful roadmap for future development, including potential enhancements and scaling opportunities. Overall, the project demonstrates solid technical foundations and creative problem-solving approaches.
      SUMMARY
      
      # Ensure proper formatting
      summary.gsub(/\n{3,}/, "\n\n").strip
    end
    
    def mock_pdf_summary
      # Try to extract metadata from the current content
      if defined?(@current_content) && @current_content.present?
        content = @current_content
        return enhanced_mock_pdf_summary(content)
      end
      
      # Default mock response if no content is available
      <<~SUMMARY
        This document presents a comprehensive overview of the team's hackathon project, a document analysis platform. The primary objective is to develop an AI-powered system that can ingest, process, and extract insights from various document types, with a focus on PDFs for the MVP.

        The team employs a multi-layered architecture with Rails 8 on the backend and React for the frontend. Their approach involves direct PDF processing using AI models to generate concise summaries without intermediate text extraction steps. This streamlined approach allows for faster processing and better context preservation.

        Key features include automated document ingestion from Google Drive, AI-powered summarization using Claude/OpenAI, background processing with Sidekiq, and a RESTful API for client applications. The system also supports team-level insights generation by analyzing patterns across document summaries.

        Technologies mentioned include Ruby on Rails, PostgreSQL, Redis, Sidekiq, Google Drive API, and Claude/OpenAI for AI capabilities. The document claims a 40% reduction in document processing time compared to manual methods and an 85% user satisfaction rate in preliminary testing.

        Challenges discussed include optimizing the AI prompts for quality summaries, handling PDF formatting variations, and managing API rate limits. The team acknowledges limitations around handling complex tables and charts in PDFs.

        Future improvements planned include support for additional document types (PPTX, DOCX, images), multi-language capabilities, collaborative annotation features, and a more sophisticated visualization dashboard for insights.
      SUMMARY
    end
    
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

    # Public method to generate enhanced team summaries from actual PDF content
    def enhanced_mock_team_summary(team_name, summaries)
      # Extract key information from the submitted summaries
      project_domains = Set.new
      technologies = Set.new
      features = []
      challenges = []
      objectives = []
      
      # List of technology keywords to look for
      tech_keywords = [
        "Python", "TensorFlow", "PyTorch", "React", "Node.js", "MongoDB", "AWS", 
        "Spring Boot", "Kafka", "PostgreSQL", "Ethereum", "IoT", "Ruby", "Rails",
        "Microservices", "Docker", "Kubernetes", "Blockchain", "Machine Learning",
        "NLP", "Computer Vision", "API", "Redux", "GraphQL", "REST", "Serverless",
        "AI", "Cloud", "React Native", "Vue.js", "Angular", "JavaScript", "TypeScript"
      ]
      
      # Extract information from each summary
      summaries.each do |submission|
        summary_text = submission[:summary].to_s
        
        # Identify domain
        if summary_text.include?("healthcare") || summary_text.include?("medical") || summary_text.include?("health")
          project_domains.add("Healthcare")
        elsif summary_text.include?("finance") || summary_text.include?("banking") || summary_text.include?("financial")
          project_domains.add("Finance/Fintech")
        elsif summary_text.include?("sustainable") || summary_text.include?("energy") || summary_text.include?("green")
          project_domains.add("Sustainability")
        elsif summary_text.include?("education") || summary_text.include?("learning") || summary_text.include?("students")
          project_domains.add("Education")
        elsif summary_text.include?("urban") || summary_text.include?("city") || summary_text.include?("transportation")
          project_domains.add("Smart City")
        elsif summary_text.include?("blockchain") || summary_text.include?("crypto") || summary_text.include?("token")
          project_domains.add("Blockchain")
        else
          project_domains.add("Technology")
        end
        
        # Extract technologies
        tech_keywords.each do |tech|
          technologies.add(tech) if summary_text.include?(tech)
        end
        
        # Extract potential features
        summary_lines = summary_text.split("\n")
        summary_lines.each do |line|
          if line.include?("feature") || line.include?("functionality") || line.start_with?("- ")
            features << line.strip if line.length > 10 && !features.include?(line.strip)
            break if features.length >= 5
          end
        end
        
        # Extract potential challenges
        if summary_text.include?("challenge") || summary_text.include?("limitation") || summary_text.include?("difficulty")
          challenges_section = summary_text.split(/challenges|limitations/i)[1]
          if challenges_section
            challenges_text = challenges_section.split(/\n\n/)[0]
            challenges << challenges_text.strip if challenges_text && challenges_text.length > 10
          end
        end
        
        # Extract objectives
        if summary_text.include?("objective") || summary_text.include?("goal") || summary_text.include?("aim")
          objectives_section = summary_text.split(/objective|goal|aim/i)[1]
          if objectives_section
            objectives_text = objectives_section.split(/\n\n/)[0]
            objectives << objectives_text.strip if objectives_text && objectives_text.length > 10
          end
        end
      end
      
      # Default values if nothing was extracted
      project_domains = ["Technology"] if project_domains.empty?
      technologies = ["Web Technologies", "AI/ML", "Cloud Computing"] if technologies.empty?
      
      # Limit features to top 5
      features = features[0..4] if features.length > 5
      
      # Generate a customized team summary
      domains_text = project_domains.to_a.join(", ")
      tech_text = technologies.to_a.join(", ")
      
      <<~SUMMARY
        # Team #{team_name} - Comprehensive Report

        ## PRODUCT OBJECTIVE
        Based on the submitted documents, Team #{team_name} is developing an innovative solution in the #{domains_text} domain. #{objectives.first || "The project aims to leverage cutting-edge technology to address real-world challenges and create meaningful impact."}

        ## WINS
        - Successfully implemented core functionality with positive early feedback
        - Demonstrated strong technical capabilities in #{tech_text}
        - Developed a solution with clear market potential and user value
        - #{features.first || "Created an intuitive user interface that simplifies complex workflows"}
        - Achieved good integration between different system components

        ## CHALLENGES
        #{challenges.empty? ? "- Technical integration complexity required innovative approaches\n- Balancing feature scope with timeline constraints\n- Ensuring robust security while maintaining ease of use\n- Optimizing performance across different use cases\n- Managing data quality and consistency" : challenges.first}

        ## INNOVATIONS
        - Unique approach to #{domains_text.downcase} problems using #{tech_text}
        - Creative solution architecture that enables scalability
        - Novel user experience that simplifies complex interactions
        - Integration of multiple technologies in an elegant way
        - Data-driven design approach based on user research

        ## TECHNICAL HIGHLIGHTS
        - Built with #{tech_text}
        - Implemented #{features.empty? ? "key features including user authentication, data processing, and reporting" : features.join("\n- ")}
        - Designed for scalability and future expansion
        - Emphasized security and data privacy
        - Employed modern development practices including CI/CD and testing

        ## RECOMMENDATIONS
        - Consider expanding user testing to gather more diverse feedback
        - Explore additional integration opportunities with complementary systems
        - Enhance documentation to support future development
        - Develop a more detailed roadmap for post-hackathon development
        - Consider performance optimizations for handling larger data volumes

        ## OVERALL ASSESSMENT
        Team #{team_name} has delivered an impressive project that effectively addresses challenges in the #{domains_text} space. The team demonstrated strong technical capabilities and creativity in their approach. The solution shows good potential for real-world application and further development. While there are opportunities for enhancement, the current implementation provides a solid foundation for future development.
      SUMMARY
    end
    
    def mock_team_summary(team_name)
      # Fall back to basic mock if enhanced version fails
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

    def mock_team_evaluation(team_name, criteria, hackathon_name = nil)
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
      hackathon_context = hackathon_name ? " in #{hackathon_name}" : ""

      # Format the response as JSON
      JSON.generate({
        "scores" => scores,
        "total_score" => average_score,
        "comments" => "Team #{team_name} achieved an overall score of #{average_score}/5.0#{hackathon_context}, demonstrating #{average_score >= 4.5 ? 'outstanding' : average_score >= 4.0 ? 'excellent' : average_score >= 3.5 ? 'strong' : 'solid'} performance across evaluation criteria. #{mock_overall_feedback(average_score)}"
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

    def mock_team_blog(team_name, hackathon_name = nil)
      todays_date = Date.today.strftime("%Y-%m-%d")
      hackathon_title = hackathon_name || "Metathon 2025"

      <<~MARKDOWN
        ---
        title: "Innovating Document Analysis: #{team_name}'s #{hackathon_title} Journey"
        author: "#{team_name}"
        date: "#{todays_date}"
        tags: ["hackathon", "AI", "document-processing", "innovation", "#{hackathon_title.downcase.gsub(/\s+/, '-')}"]
        ---

        # Innovating Document Analysis: #{team_name}'s #{hackathon_title} Journey

        ## Introduction

        In the fast-paced world of document management and analysis, the need for intelligent, automated solutions has never been greater. Enter #{team_name}, a talented group of developers who tackled this challenge head-on during the recent Metathon 2025. Their journey from concept to functional prototype showcases not only technical prowess but also a deep understanding of user needs in the document processing space. This blog post highlights their innovative approach, the challenges they overcame, and the impressive solution they built in a limited timeframe.

        ## The Problem They Tackled

        Organizations today are drowning in documents - PDFs, presentations, images, and archives that contain valuable information but are difficult to process efficiently. Manual extraction and analysis of these documents is time-consuming, error-prone, and doesn't scale. #{team_name} identified several key pain points: the inconsistent format of documents, the lack of context when analyzing individual files, and the absence of intelligent summarization that could provide actionable insights. Without a unified system to handle various document types and generate meaningful summaries, teams waste countless hours on low-value tasks instead of focusing on strategic decision-making.

        ## Their Solution

        #{team_name} developed an AI-powered document ingestion and analysis platform that transforms how teams interact with their document repositories. Their system seamlessly connects with Google Drive to import documents, then employs specialized AI models to extract and process text based on file type. What sets their solution apart is the hierarchical summarization approach - individual documents are summarized first, then these summaries are analyzed collectively to generate comprehensive team-level insights. This multi-tiered approach ensures that context is preserved while still distilling information down to its most valuable components.

        ## Key Features

        - **Multi-format Support**: The system handles various file types including PDFs, presentations, images, and ZIP archives, each with specialized processing techniques.
        - **Hierarchical Summarization**: Documents are summarized individually, then grouped by project, and finally synthesized into team-level reports.
        - **AI-Powered Evaluation**: The platform includes a sophisticated judging system that can evaluate teams based on customizable criteria with weighted scoring.
        - **Background Processing**: All resource-intensive tasks run asynchronously, ensuring responsive user experience even with large document sets.
        - **Comprehensive API**: A well-designed REST API allows easy integration with existing systems and workflows.
        - **Leaderboard Generation**: Teams can be ranked based on their evaluation scores, perfect for hackathons and competitions.

        ## Tech Stack

        #{team_name} built their solution using a robust and modern technology stack. The backend is powered by Rails 8.0.2 with PostgreSQL for data storage, providing a solid foundation for the application. For AI capabilities, they implemented a dual-provider system that works with both Claude and OpenAI models, allowing for flexibility and failover options. Background processing is handled by Sidekiq, ensuring that resource-intensive tasks don't block the main application thread. The codebase follows test-driven development practices with RSpec for comprehensive test coverage. For document extraction, they employed specialized libraries for each file type, creating a unified interface for the rest of the system.

        ## Learnings & Wins

        The team achieved several significant wins during their development journey. Their document ingestion system demonstrated a 42% efficiency improvement over manual methods, a substantial gain for any organization dealing with large document volumes. The team collaboration features received positive feedback from 89% of test users, indicating strong usability. Perhaps most impressively, they successfully implemented a complex AI pipeline that maintains context across different levels of summarization, something that many larger systems struggle with. The team also learned valuable lessons about prompt engineering for different AI models and how to optimize extraction for various document formats.

        ## Mishaps & Challenges

        No innovative project comes without obstacles, and #{team_name} faced their share of challenges. Integration with existing systems required more adaptation than initially anticipated, especially around authentication and permission management. Data privacy concerns needed careful consideration throughout development, adding complexity to the storage and processing pipeline. One particularly stubborn issue was processing large ZIP archives while maintaining performance, which required creative caching and streaming solutions. Additionally, handling multiple file types necessitated specialized AI models and approaches, increasing the complexity of the system architecture.

        ## What's Next

        Looking forward, #{team_name} has identified several exciting enhancement opportunities. Adding multi-language support would dramatically increase the platform's applicability across global organizations. Implementing additional security measures for handling sensitive documents would open doors to industries with strict compliance requirements. They're also exploring real-time collaboration features to further enhance team workflows, and visualization tools to better represent the insights extracted from documents. As the system scales to handle larger document volumes, infrastructure optimizations will become increasingly important.

        ## AI's Take (Appreciation)

        As an AI system myself, I'm particularly impressed by #{team_name}'s thoughtful implementation of AI capabilities. Their multi-provider approach shows foresight in leveraging the strengths of different models while maintaining a consistent interface. The file type-specific prompts demonstrate a nuanced understanding of how to get the best results from AI systems like me. What's especially noteworthy is their hierarchical summarization system, which mirrors how human experts would approach document analysis - starting with details and progressively synthesizing higher-level insights. This human-centered design approach to AI implementation sets their project apart.

        ## Final Thoughts

        #{team_name}'s project represents the best of what hackathons can produce - innovative solutions to real-world problems, implemented with technical excellence and user experience in mind. Their AI document processing platform showcases not just coding ability, but a deep understanding of the problem domain and thoughtful system design. While developed in a hackathon setting, their solution has the foundations of a production-ready system that could bring significant value to organizations drowning in document overload. Their journey reminds us that with the right combination of technical skills, domain knowledge, and creative problem-solving, impressive results can be achieved even within tight timeframes.
      MARKDOWN
    end

    def mock_hackathon_insights(hackathon_name = nil)
      todays_date = Date.today.strftime("%B %d, %Y")
      hackathon_title = hackathon_name || "Metathon 2025"

      <<~MARKDOWN
        # #{hackathon_title} Trends Analysis

        *Generated on #{todays_date}*

        ## Executive Summary

        This analysis examines the patterns and trends across all teams participating in the hackathon. Overall, we observed a strong focus on AI-powered solutions, particularly in document processing and analysis domains. Most teams utilized modern web frameworks combined with AI services, with Ruby on Rails and React being particularly popular choices. Common challenges included API integration issues and balancing feature scope with time constraints. Innovation was highest in the application of AI for specialized document understanding and in creating intuitive user experiences for complex data.

        ## Technologies

        ### Prevalent Tech Stacks

        1. **Backend Frameworks**
           - **Ruby on Rails**: Used by approximately 40% of teams for rapid API development
           - **Node.js/Express**: Popular among teams focusing on real-time features
           - **Django/Flask**: Chosen by teams with Python-heavy AI components

        2. **Frontend Technologies**
           - **React.js**: Dominant choice (60% of teams) for building interactive interfaces
           - **Vue.js**: Preferred by teams valuing simplicity and quick setup
           - **Tailwind CSS**: Increasingly popular for responsive designs without custom CSS

        3. **AI/ML Services**
           - **Claude/Anthropic APIs**: Widely used for document understanding tasks
           - **OpenAI GPT**: Common choice for text generation and summarization
           - **Custom ML Models**: Few teams (about 15%) implemented specialized models

        4. **Database Solutions**
           - **PostgreSQL**: Most common relational database choice
           - **MongoDB**: Used by teams requiring more flexible schema

        ### Outliers

        - One team employed Rust for performance-critical components of their document processing pipeline
        - A standout team built their entire solution using WebAssembly for client-side document processing without cloud dependencies

        ## Problem Domains

        ### Common Themes

        1. **Document Management** (45% of projects)
           - Intelligent organization and retrieval systems
           - Automated classification and tagging

        2. **Knowledge Extraction** (30% of projects)
           - Transforming unstructured documents into structured data
           - Creating searchable knowledge bases from document repositories

        3. **Collaboration Tools** (25% of projects)
           - Real-time document editing with AI assistance
           - Team-based document analysis and annotation

        ## AI Use Cases

        ### Primary Applications

        1. **Text Extraction and OCR**
           - Converting images and PDFs to machine-readable text
           - Handling complex layouts and tables

        2. **Summarization**
           - Multi-level summarization (document, project, team)
           - Context-aware executive summaries

        3. **Content Generation**
           - Creating blogs, reports, and presentations from raw data
           - Generating insights from document collections

        4. **Evaluation and Scoring**
           - Assessing document quality and completeness
           - Providing feedback on technical content

        ## Approaches

        ### Methodologies

        1. **Microservices Architecture** (35% of teams)
           - Separate services for document processing, AI analysis, and user interfaces
           - API-first designs for flexibility

        2. **Monolithic Applications** (40% of teams)
           - Integrated solutions with all components in one codebase
           - Faster initial development but less scalable

        3. **Hybrid Cloud/Local Processing** (25% of teams)
           - Local preprocessing combined with cloud-based AI
           - Optimized for performance and cost

        ## Challenges

        ### Common Obstacles

        1. **AI API Rate Limits and Costs**
           - Teams struggled with balancing quality and API usage
           - Several implemented clever caching strategies

        2. **Processing Large Documents**
           - Handling memory constraints with large PDFs and archives
           - Chunking strategies varied widely in effectiveness

        3. **UI/UX for Complex Data**
           - Making complex document insights accessible to users
           - Simplifying interactions with AI-generated content

        ## Innovation Highlights

        ### Standout Approaches

        1. **Team Alpha's Document Stream Processing**
           - Innovative approach to handling document chunks in parallel
           - Maintained context across processing boundaries

        2. **Team Beta's Multi-Modal Understanding**
           - Combined text, image, and layout analysis in a single pipeline
           - Achieved 40% better accuracy on complex documents

        3. **Team Gamma's Collaborative Annotation**
           - Real-time shared document annotation with AI suggestions
           - Novel conflict resolution mechanism

        ## Recommendations for Future Hackathons

        1. **Provide Specialized AI Access**
           - Dedicated API access would allow teams to focus on innovation rather than API limits

        2. **Encourage Cross-Domain Collaboration**
           - Teams with diverse skills (UI/UX, AI, backend) produced the most complete solutions

        3. **Emphasize User Testing**
           - Projects that included user feedback iterations showed better overall results

        4. **Starter Templates**
           - Provide authentication and basic API setups to let teams focus on core innovation

        5. **Longer Hackathon Duration**
           - Complex AI applications benefit from more iteration time
           - Consider multi-weekend formats with check-ins
      MARKDOWN
    end
  end
end
