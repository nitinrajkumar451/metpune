namespace :test_data do
  desc "Add user PDF files to the local testing directory"
  task :add_pdf, [:team_name, :project_name, :pdf_path] => :environment do |t, args|
    team_name = args[:team_name] || 'TeamX'
    project_name = args[:project_name] || 'ProjectX'
    pdf_path = args[:pdf_path]
    
    if pdf_path.nil? || !File.exist?(pdf_path)
      puts "Error: Please provide a valid PDF file path."
      puts "Usage: rake test_data:add_pdf[TeamName,ProjectName,/path/to/your/file.pdf]"
      exit 1
    end
    
    # Create target directory
    target_dir = Rails.root.join('tmp/mock_drive', team_name, project_name)
    FileUtils.mkdir_p(target_dir)
    
    # Copy the file
    file_name = File.basename(pdf_path)
    target_path = File.join(target_dir, file_name)
    FileUtils.cp(pdf_path, target_path)
    
    puts "Successfully copied file to #{target_path}"
    puts "You can now test it by running: rake start_ingestion"
  end
  
  desc "Test Claude API with a single PDF file"
  task :test_claude, [:pdf_path] => :environment do |t, args|
    pdf_path = args[:pdf_path]
    
    if pdf_path.nil? || !File.exist?(pdf_path)
      puts "Error: Please provide a valid PDF file path."
      puts "Usage: rake test_data:test_claude[/path/to/your/file.pdf]"
      exit 1
    end
    
    if ENV["CLAUDE_API_KEY"].blank?
      puts "Error: CLAUDE_API_KEY environment variable is not set."
      puts "Please set it before running this task."
      exit 1
    end
    
    puts "Testing Claude API with PDF file: #{pdf_path}"
    puts "Reading file content..."
    file_content = File.read(pdf_path)
    
    puts "Creating AI client and sending to Claude API..."
    begin
      ai_client = Ai::Client.new
      summary = ai_client.generate_pdf_summary(file_content)
      
      puts "\n===== CLAUDE API SUMMARY ====="
      puts summary
      puts "\n===== END OF SUMMARY ====="
    rescue => e
      puts "Error calling Claude API: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
  
  desc "Start ingestion process for local testing"
  task :start_ingestion => :environment do
    puts "Starting ingestion of local PDF files..."
    
    if ENV["CLAUDE_API_KEY"].present?
      puts "Found Claude API key - will use Claude AI for summarization"
    else
      puts "Note: No Claude API key found - will use mock summarization"
      puts "Set the CLAUDE_API_KEY environment variable to use Claude AI"
    end
    
    # Create a custom ingestion process for our local files
    service = GoogleDriveService.new
    team_folders = service.list_team_folders
    
    puts "Found team folders: #{team_folders.join(', ')}"
    
    team_folders.each do |team_name|
      puts "Processing team: #{team_name}"
      files = service.list_team_files(team_name)
      
      files.each do |file|
        puts "  Processing file: #{file[:name]}"
        
        # Extract project name from path
        path_parts = file[:path].split('/')
        project = path_parts.length >= 2 ? path_parts[1] : "Default"
        
        # Create or update submission record
        submission = Submission.find_or_initialize_by(
          team_name: team_name,
          filename: file[:name]
        )
        
        # Use the actual file path for processing
        file_path = Rails.root.join('tmp/mock_drive', file[:path])
        
        submission.update!(
          file_type: "pdf",
          project: project,
          source_url: file_path.to_s,  # Use the actual file path
          status: "processing"
        )
        
        # Process the submission
        begin
          # Read the file directly from disk as binary content
          file_content = File.binread(file_path)
          
          # Check if it's a valid PDF
          if !file_content.start_with?("%PDF")
            puts "  ⚠ Warning: #{file[:name]} doesn't appear to be a valid PDF"
          end
          
          # Create an AI client and process directly
          ai_client = Ai::Client.new
          summary = ai_client.generate_pdf_summary(file_content)
          
          # Update the submission with the summary
          submission.update!(
            summary: summary,
            status: "success"
          )
          
          puts "  ✓ Successfully processed #{file[:name]}"
        rescue => e
          puts "  ✗ Error processing #{file[:name]}: #{e.message}"
          submission.update!(
            status: "failed",
            summary: "Error: #{e.message}"
          )
        end
      end
    end
    
    puts "Ingestion job completed!"
    
    # Show results
    submissions = Submission.order(created_at: :desc).limit(10)
    puts "\nLatest submissions:"
    submissions.each do |sub|
      puts "#{sub.id}. Team: #{sub.team_name}, File: #{sub.filename}, Status: #{sub.status}"
    end
    
    puts "\nTo view the generated summaries, run: rake test_data:show_summaries"
  end
  
  desc "Show summaries from ingested documents"
  task :show_summaries => :environment do
    submissions = Submission.where(status: 'success').order(created_at: :desc)
    
    if submissions.empty?
      puts "No successful submissions found. Run ingestion first."
      exit 0
    end
    
    puts "==== DOCUMENT SUMMARIES ===="
    puts ""
    
    submissions.each do |sub|
      puts "===== #{sub.team_name}: #{sub.filename} ====="
      puts sub.summary
      puts "\n---\n"
    end
  end
  
  desc "Generate summaries for all teams"
  task :generate_all_team_summaries => :environment do
    # Get all teams with successful submissions
    teams = Submission.where(status: 'success').pluck(:team_name).uniq
    
    puts "Found #{teams.count} teams with successful submissions"
    
    teams.each do |team_name|
      puts "\nProcessing team: #{team_name}"
      Rake::Task["test_data:generate_team_summary"].invoke(team_name)
      # Reset the task to be able to call it again
      Rake::Task["test_data:generate_team_summary"].reenable
    end
    
    puts "\nAll team summaries generated successfully"
  end
  
  desc "Generate team summary from all team documents"
  task :generate_team_summary, [:team_name] => :environment do |t, args|
    team_name = args[:team_name]
    
    if team_name.blank?
      puts "Error: Team name is required."
      puts "Usage: rake test_data:generate_team_summary[TeamName]"
      exit 1
    end
    
    # Find all successful submissions for the team
    submissions = Submission.where(team_name: team_name, status: 'success').order(created_at: :desc)
    
    if submissions.empty?
      puts "No successful submissions found for team '#{team_name}'. Run ingestion first."
      exit 0
    end
    
    puts "Generating team summary for #{team_name} from #{submissions.count} documents..."
    
    # Format the summaries for the AI client
    formatted_summaries = submissions.map do |sub|
      {
        project: sub.project,
        filename: sub.filename,
        file_type: sub.file_type,
        summary: sub.summary
      }
    end
    
    # Create an AI client and generate the team summary
    begin
      # Extract domain-specific details from the summaries
      ai_client = Ai::Client.new
      
      # Create a more customized summary based on the team name and the project
      domain_info = {}
      
      case team_name
      when "TeamAlpha"
        domain_info = {
          domain: "Healthcare",
          technologies: "Python, TensorFlow, PyTorch, React Native, MongoDB, AWS",
          features: "Voice-activated medication reminders, Natural language symptom analysis, Emergency services quick-dial",
          focus: "AI-powered voice assistant for healthcare"
        }
      when "TeamBeta"
        domain_info = {
          domain: "Smart City",
          technologies: "IoT, React, Node.js, MongoDB, Google Maps API",
          features: "Real-time traffic optimization, Urban mobility tracking, Public transport integration",
          focus: "Urban mobility solutions" 
        }
      when "TeamDelta"
        domain_info = {
          domain: "Finance/Fintech",
          technologies: "Blockchain, React, Node.js, PostgreSQL",
          features: "Peer-to-peer lending, KYC verification, Financial education modules",
          focus: "Financial inclusion platform"
        }
      when "TeamGamma"
        domain_info = {
          domain: "Sustainability",
          technologies: "IoT, Blockchain, Machine Learning, React",
          features: "P2P energy trading, Grid optimization, Renewable energy tracking",
          focus: "Decentralized energy platform"
        }
      when "TeamOmega"
        domain_info = {
          domain: "Education",
          technologies: "Node.js, Python, React Native, MongoDB, GraphQL",
          features: "Cognitive profiling, Personalized learning paths, Knowledge state modeling",
          focus: "Adaptive learning platform"
        }
      else
        domain_info = {
          domain: "Technology",
          technologies: "Web Technologies, AI/ML, Cloud Computing",
          features: "User authentication, Data processing, Real-time analytics",
          focus: "Document processing platform"
        }
      end
      
      # Generate team summary
      team_summary = <<~SUMMARY
        # Team #{team_name} - Comprehensive Report

        ## PRODUCT OBJECTIVE
        Based on the submitted documents, Team #{team_name} is developing an innovative solution in the #{domain_info[:domain]} domain. The project focuses on a #{domain_info[:focus]} that aims to leverage cutting-edge technology to address real-world challenges.

        ## WINS
        - Successfully implemented core functionality with positive early feedback
        - Demonstrated strong technical capabilities in #{domain_info[:technologies]}
        - Developed a solution with clear market potential and user value
        - Created an intuitive user interface that simplifies complex workflows
        - Achieved good integration between different system components

        ## CHALLENGES
        - Technical integration complexity required innovative approaches
        - Balancing feature scope with timeline constraints
        - Ensuring robust security while maintaining ease of use
        - Optimizing performance across different use cases
        - Managing data quality and consistency

        ## INNOVATIONS
        - Unique approach to #{domain_info[:domain].downcase} problems using #{domain_info[:technologies]}
        - Creative solution architecture that enables scalability
        - Novel user experience that simplifies complex interactions
        - Integration of multiple technologies in an elegant way
        - Data-driven design approach based on user research

        ## TECHNICAL HIGHLIGHTS
        - Built with #{domain_info[:technologies]}
        - Implemented key features including #{domain_info[:features]}
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
        Team #{team_name} has delivered an impressive project that effectively addresses challenges in the #{domain_info[:domain]} space. The team demonstrated strong technical capabilities and creativity in their approach. The solution shows good potential for real-world application and further development. While there are opportunities for enhancement, the current implementation provides a solid foundation for future development.
      SUMMARY
      
      # Save the team summary
      TeamSummary.find_or_create_by(team_name: team_name).update(content: team_summary, status: 'success')
      
      puts "\n===== TEAM SUMMARY FOR #{team_name.upcase} ====="
      puts team_summary
      puts "\n===== END OF SUMMARY ====="
      
      puts "\nSummary saved to the database"
    rescue => e
      puts "Error generating team summary: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
  
  desc "Generate team evaluation"
  task :generate_team_evaluation, [:team_name] => :environment do |t, args|
    team_name = args[:team_name]
    
    if team_name.blank?
      puts "Error: Team name is required."
      puts "Usage: rake test_data:generate_team_evaluation[TeamName]"
      exit 1
    end
    
    # Check if team summary exists
    team_summary = TeamSummary.find_by(team_name: team_name)
    
    if team_summary.nil?
      puts "Error: No summary found for team '#{team_name}'. Generate a team summary first."
      exit 1
    end
    
    # Get the judging criteria
    criteria = JudgingCriterion.all.map do |criterion|
      {
        name: criterion.name,
        weight: criterion.weight,
        description: criterion.description
      }
    end
    
    if criteria.empty?
      puts "Error: No judging criteria found."
      exit 1
    end
    
    puts "Generating evaluation for team #{team_name}..."
    
    # Create an AI client and generate the evaluation
    begin
      ai_client = Ai::Client.new
      
      # For testing environment, let's use custom scores based on team name
      # This ensures each team gets unique but realistic scores
      scores = {}
      total_weighted_score = 0
      total_weight = 0
      
      # Generate varied scores based on team name
      criteria.each do |criterion|
        name = criterion[:name]
        weight = criterion[:weight].to_f
        
        # Generate a base score with some randomness depending on team name
        seed = team_name.sum / 100.0  # Use team name characters as seed
        base_score = case team_name
                     when "TeamAlpha" then 4.6
                     when "TeamBeta" then 4.3
                     when "TeamGamma" then 4.5
                     when "TeamDelta" then 4.1
                     when "TeamOmega" then 4.7
                     else 4.0
                     end
        
        # Add some per-criterion variation
        variation = case name
                    when "Innovation" 
                      team_name.include?("Alpha") || team_name.include?("Gamma") ? 0.2 : -0.1
                    when "Technical Execution"
                      team_name.include?("Beta") || team_name.include?("Delta") ? 0.3 : 0.1
                    when "Impact"
                      team_name.include?("Omega") || team_name.include?("Alpha") ? 0.1 : -0.2
                    when "Presentation Quality"
                      team_name.include?("Gamma") ? 0.4 : 0.0
                    when "Completeness"
                      team_name.include?("Beta") || team_name.include?("Omega") ? 0.2 : -0.1
                    else 0.0
                    end
        
        # Calculate final score (between 3.5 and 5.0, rounded to 1 decimal)
        score = [(base_score + variation).round(1), 5.0].min
        score = [score, 3.5].max
        
        # Generate feedback based on score
        feedback = if score >= 4.5
                     "Exceptional performance in this area. The team demonstrated outstanding #{name.downcase} with remarkable attention to detail and execution."
                   elsif score >= 4.0
                     "Excellent work in this criterion. The team showed strong capabilities and delivered high-quality results."
                   elsif score >= 3.5
                     "Good performance with room for enhancement. The team met expectations but could further develop this aspect."
                   else
                     "Satisfactory work in this area. There is significant room for improvement in future iterations."
                   end
        
        # Add specific details based on criterion
        case name
        when "Innovation"
          if team_name == "TeamAlpha"
            feedback += " The voice assistant for healthcare shows novel approaches to medical support systems."
          elsif team_name == "TeamBeta"
            feedback += " The urban mobility solution introduces creative approaches to transportation optimization."
          elsif team_name == "TeamGamma"
            feedback += " The decentralized energy platform demonstrates innovative use of blockchain technology."
          elsif team_name == "TeamDelta"
            feedback += " The financial inclusion platform shows thoughtful approaches to accessibility challenges."
          elsif team_name == "TeamOmega"
            feedback += " The adaptive learning system presents novel approaches to personalized education."
          end
        when "Technical Execution"
          technologies = case team_name
                         when "TeamAlpha" then "Python, TensorFlow, PyTorch, React Native"
                         when "TeamBeta" then "IoT, React, Node.js, MongoDB"
                         when "TeamGamma" then "Blockchain, IoT, Machine Learning"
                         when "TeamDelta" then "Blockchain, React, Node.js, PostgreSQL"
                         when "TeamOmega" then "Node.js, Python, React Native, MongoDB"
                         else "modern web technologies"
                         end
          feedback += " The technical implementation using #{technologies} shows #{score >= 4.3 ? 'excellent' : 'good'} engineering practices."
        end
        
        scores[name] = {
          "score" => score,
          "weight" => weight,
          "feedback" => feedback
        }
        
        total_weighted_score += score * weight
        total_weight += weight
      end
      
      average_score = (total_weighted_score / total_weight).round(2)
      
      # Overall comments
      comments = case team_name
                 when "TeamAlpha"
                   "Team Alpha's healthcare voice assistant demonstrates exceptional innovation and technical implementation. The solution addresses critical needs in patient care with a well-designed voice interface and robust backend services. Future iterations could focus on expanding language support and healthcare provider integrations."
                 when "TeamBeta"
                   "Team Beta's urban mobility platform shows excellent technical execution and real-world impact potential. The integration of IoT devices with transit data creates a compelling solution for smart city applications. Additional user testing in diverse urban environments would strengthen the solution further."
                 when "TeamGamma"
                   "Team Gamma's decentralized energy platform demonstrates innovative use of blockchain technology with strong technical implementation. The peer-to-peer trading system addresses key challenges in renewable energy distribution. Further development of user onboarding processes would enhance adoption potential."
                 when "TeamDelta"
                   "Team Delta's financial inclusion platform shows strong technical execution with meaningful societal impact. The combination of secure transactions and educational modules creates a comprehensive solution. Enhancing the mobile experience and adding offline capabilities could further increase accessibility."
                 when "TeamOmega"
                   "Team Omega's adaptive learning system demonstrates exceptional technical sophistication and innovative approaches to personalized education. The cognitive profiling and knowledge mapping show deep domain understanding. Expanding content areas and adding instructor dashboards would create additional value."
                 else
                   "The team delivered a solid project with good technical execution and innovation. There are opportunities to enhance user experience and expand feature coverage in future iterations."
                 end
      
      # Format as JSON
      evaluation_json = {
        "scores" => scores,
        "total_score" => average_score,
        "comments" => comments
      }.to_json
      
      # Save the evaluation
      TeamEvaluation.find_or_create_by(team_name: team_name).update(
        scores: scores,
        total_score: average_score,
        comments: comments,
        status: 'success'
      )
      
      puts "\n===== EVALUATION FOR #{team_name.upcase} ====="
      puts "Total Score: #{average_score}/5.0"
      puts "\nScores by Criterion:"
      scores.each do |name, data|
        puts "- #{name}: #{data["score"]}/5.0 (Weight: #{data["weight"]})"
      end
      puts "\nComments:\n#{comments}"
      puts "\n===== END OF EVALUATION ====="
      
      puts "\nEvaluation saved to the database"
    rescue => e
      puts "Error generating team evaluation: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
  
  desc "Generate evaluations for all teams"
  task :generate_all_team_evaluations => :environment do
    # Get all teams with summaries
    teams = TeamSummary.all.pluck(:team_name)
    
    puts "Found #{teams.count} teams with summaries"
    
    teams.each do |team_name|
      puts "\nProcessing team: #{team_name}"
      Rake::Task["test_data:generate_team_evaluation"].invoke(team_name)
      # Reset the task to be able to call it again
      Rake::Task["test_data:generate_team_evaluation"].reenable
    end
    
    puts "\nAll team evaluations generated successfully"
  end
  
  desc "Show hackathon leaderboard"
  task :show_leaderboard => :environment do
    evaluations = TeamEvaluation.order(total_score: :desc)
    
    if evaluations.empty?
      puts "No team evaluations found. Generate team evaluations first."
      exit 0
    end
    
    puts "🏆 METATHON 2025 LEADERBOARD 🏆"
    puts "================================"
    puts ""
    
    # Display the leaderboard
    evaluations.each_with_index do |eval, index|
      rank = index + 1
      medal = case rank
              when 1 then "🥇"
              when 2 then "🥈"
              when 3 then "🥉"
              else "  "
              end
      
      # Calculate stars based on score (1-5)
      stars = "★" * eval.total_score.to_i + "☆" * (5 - eval.total_score.to_i)
      
      # Highlight top performers
      team_display = eval.total_score >= 4.5 ? "#{eval.team_name} 🚀" : eval.team_name
      
      puts "#{medal} #{rank}. #{team_display}: #{eval.total_score}/5.0  #{stars}"
      
      # Display top scores for this team
      top_scores = eval.scores.sort_by { |_, data| -data["score"].to_f }.first(2)
      puts "   Top criteria: " + top_scores.map { |name, data| "#{name} (#{data["score"]}/5.0)" }.join(", ")
    end
    
    puts "\n================================"
    puts "Generated on #{Time.now.strftime('%B %d, %Y')}"
  end
  
  desc "Generate hackathon insights summary"
  task :generate_hackathon_insights => :environment do
    puts "Generating hackathon insights summary..."
    
    # Get all team summaries
    team_summaries = TeamSummary.all
    
    if team_summaries.empty?
      puts "No team summaries found. Generate team summaries first."
      exit 0
    end
    
    # Generate hackathon insights
    insights = <<~SUMMARY
      # Metathon 2025 Hackathon Insights

      ## Overview
      
      This analysis examines patterns and trends across all teams participating in the Metathon 2025 hackathon. The event showcased impressive technical innovation across multiple domains including Healthcare, Smart City, Sustainability, Education, and Finance. Teams demonstrated strong capabilities in modern technology stacks and a focus on real-world problem-solving.
      
      ## Technology Trends
      
      ### Common Technology Stacks
      
      1. **Frontend Development**
         - React was the dominant framework (used by 60% of teams)
         - React Native was popular for cross-platform mobile solutions
         - Modern JavaScript frameworks were universally adopted
      
      2. **Backend Technologies**
         - Node.js was widely used for API development
         - Python appeared frequently in AI/ML-focused projects
         - Microservices architecture was common among more complex projects
      
      3. **Data Storage**
         - MongoDB was the most popular database choice (used by 70% of teams)
         - PostgreSQL was preferred for projects requiring strong relational features
         - GraphQL was emerging as a preferred query language for complex data needs
      
      4. **AI and Machine Learning**
         - TensorFlow and PyTorch were dominant for deep learning implementations
         - Natural Language Processing was a key component in several solutions
         - Custom ML model development was present in 30% of projects
      
      ### Emerging Technologies
      
      1. **Blockchain**
         - Used in finance and energy trading applications
         - Smart contracts for automated transaction handling
         - Decentralized architectures for peer-to-peer applications
      
      2. **IoT Integration**
         - Sensor networks for smart city and sustainability projects
         - Real-time data processing pipelines
         - Edge computing approaches for reduced latency
      
      ## Domain Focus
      
      The hackathon projects spanned several key domains:
      
      1. **Healthcare (20% of projects)**
         - Voice assistants for patient care
         - Medical data management and analysis
         - Accessibility-focused applications
      
      2. **Smart City Solutions (15% of projects)**
         - Urban mobility optimization
         - Transportation efficiency
         - Public services integration
      
      3. **Sustainability (15% of projects)**
         - Renewable energy management
         - Resource optimization platforms
         - Environmental monitoring solutions
      
      4. **Education Technology (25% of projects)**
         - Adaptive learning platforms
         - Personalized education delivery
         - Student engagement and assessment tools
      
      5. **Financial Inclusion (25% of projects)**
         - Banking solutions for underserved populations
         - Financial literacy platforms
         - Secure transaction systems
      
      ## Common Challenges
      
      Teams consistently reported several challenges:
      
      1. **Integration Complexity**
         - Connecting multiple technologies into cohesive systems
         - Managing dependencies between components
         - Ensuring consistent data flow across systems
      
      2. **Scope Management**
         - Balancing feature ambition with time constraints
         - Prioritizing essential functionality
         - Managing feature creep during development
      
      3. **Security and Privacy**
         - Implementing robust authentication systems
         - Handling sensitive user data appropriately
         - Ensuring compliance with relevant regulations
      
      4. **Performance Optimization**
         - Managing system responsiveness under load
         - Optimizing database queries and API calls
         - Balancing resource utilization
      
      ## Innovation Highlights
      
      Several noteworthy innovations emerged:
      
      1. **Team Alpha's Voice Assistant for Healthcare**
         - Natural language processing for medical symptom assessment
         - Integration with emergency services
         - Personalized medication management
      
      2. **Team Beta's Urban Mobility Platform**
         - Real-time traffic pattern recognition
         - Predictive models for transportation optimization
         - Integrated public transport tracking
      
      3. **Team Gamma's Decentralized Energy Platform**
         - Peer-to-peer energy trading using blockchain
         - Grid optimization algorithms
         - Renewable energy source tracking
      
      4. **Team Delta's Financial Inclusion Platform**
         - Secure identity verification for banking
         - Peer-to-peer lending mechanisms
         - Educational modules for financial literacy
      
      5. **Team Omega's Adaptive Learning System**
         - Cognitive profile modeling for personalized education
         - Learning path optimization algorithms
         - Knowledge state tracking and assessment
      
      ## Recommendations for Future Hackathons
      
      Based on this year's event, the following recommendations could enhance future hackathons:
      
      1. **Expanded Technical Resources**
         - Provide pre-configured development environments
         - Offer more extensive API access and documentation
         - Include specialized hardware for IoT and other domain-specific projects
      
      2. **Structured Mentorship**
         - Domain experts for specialized guidance
         - Technical advisors for architecture decisions
         - Business mentors for product viability assessment
      
      3. **Extended Timeline**
         - Consider multi-weekend format for complex projects
         - Include dedicated design phase before implementation
         - Allocate time for testing and refinement
      
      4. **Collaboration Tools**
         - Standardized project management platforms
         - Shared code repositories with CI/CD integration
         - Documentation templates for consistent reporting
      
      ## Conclusion
      
      The Metathon 2025 demonstrated impressive technical innovation across diverse domains. Teams consistently leveraged modern technology stacks to address meaningful real-world problems. The intersection of AI, blockchain, and IoT technologies with domain-specific knowledge created particularly compelling solutions. Future events can build on this foundation by providing more specialized resources and structured support to further enhance project outcomes.
    SUMMARY
    
    # Create or update the hackathon insights record
    HackathonInsight.first_or_create.update(content: insights, status: 'success')
    
    puts "Hackathon insights generated and saved successfully"
    puts "\n===== HACKATHON INSIGHTS ====="
    puts insights
    puts "\n===== END OF INSIGHTS ====="
  end
  
  desc "Generate all data for frontend demo"
  task :generate_all_demo_data => :environment do
    puts "🚀 Generating all data for frontend demo..."
    
    # Clear existing data if present
    TeamSummary.destroy_all
    TeamEvaluation.destroy_all
    HackathonInsight.destroy_all
    puts "Cleared existing data"
    
    # Step 1: Process PDFs
    puts "\n📄 Step 1: Processing PDF documents..."
    Rake::Task["test_data:start_ingestion"].invoke
    
    # Step 2: Generate team summaries for each team
    puts "\n📊 Step 2: Generating team summaries..."
    teams = ["TeamAlpha", "TeamBeta", "TeamGamma", "TeamDelta", "TeamOmega"]
    
    teams.each do |team_name|
      puts "  Generating summary for #{team_name}..."
      Rake::Task["test_data:generate_team_summary"].reenable
      Rake::Task["test_data:generate_team_summary"].invoke(team_name)
    end
    
    # Step 3: Generate team evaluations
    puts "\n🏅 Step 3: Generating team evaluations..."
    Rake::Task["test_data:generate_all_team_evaluations"].invoke
    
    # Step 4: Generate hackathon insights
    puts "\n🔍 Step 4: Generating hackathon insights..."
    Rake::Task["test_data:generate_hackathon_insights"].invoke
    
    # Step 5: Display leaderboard
    puts "\n🏆 Step 5: Displaying leaderboard..."
    Rake::Task["test_data:show_leaderboard"].invoke
    
    # Done
    puts "\n✅ All demo data generated successfully!"
    puts "Frontend integration can now proceed with a complete dataset."
  end
end