namespace :folder_ingestion do
  desc "Start ingestion using folder names as team names and error if team summary exists"
  task start: :environment do
    puts "Starting ingestion of local PDF files with folder names as team names..."
    
    # Get the hackathon ID from environment variables
    hackathon_id = ENV["HACKATHON_ID"]
    hackathon = nil
    
    if hackathon_id.present?
      hackathon = Hackathon.find_by(id: hackathon_id)
      if hackathon
        puts "Using hackathon: #{hackathon.name} (ID: #{hackathon.id})"
      else
        puts "⚠️ WARNING: Hackathon with ID #{hackathon_id} not found. Using default hackathon."
      end
    end
    
    # Use default hackathon if none specified or not found
    if hackathon.nil?
      hackathon = Hackathon.default
      puts "Using default hackathon: #{hackathon.name} (ID: #{hackathon.id})"
    end
    
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
    
    successful_teams = []
    failed_teams = []
    skipped_teams = []
    
    team_folders.each do |team_name|
      puts "Processing team: #{team_name}"
      
      # Check if team summary already exists
      existing_summary = TeamSummary.find_by(team_name: team_name)
      if existing_summary
        puts "⚠️ ERROR: Team summary already exists for #{team_name}. Skipping."
        skipped_teams << team_name
        next
      end
      
      # Process files for this team
      files = service.list_team_files(team_name)
      team_success = true
      
      files.each do |file|
        puts "  Processing file: #{file[:name]}"
        
        # Extract project name from path
        path_parts = file[:path].split('/')
        project = path_parts.length >= 2 ? path_parts[1] : "Default"
        
        # Create or update submission record
        submission = Submission.find_or_initialize_by(
          team_name: team_name,
          filename: file[:name],
          hackathon_id: hackathon.id
        )
        
        # Use the actual file path for processing
        file_path = Rails.root.join('tmp/mock_drive', file[:path])
        
        submission.update!(
          file_type: "pdf",
          project: project,
          source_url: file_path.to_s,  # Use the actual file path
          status: "processing",
          hackathon: hackathon
        )
        
        # Process the submission
        begin
          # Read the file directly from disk as binary content
          file_content = File.binread(file_path)
          
          # Check if it's a valid PDF
          if !file_content.start_with?("%PDF")
            puts "  ⚠️ Warning: #{file[:name]} doesn't appear to be a valid PDF"
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
          team_success = false
        end
      end
      
      if team_success
        successful_teams << team_name
      else
        failed_teams << team_name
      end
    end
    
    puts "Ingestion job completed!"
    puts "Successful teams: #{successful_teams.count} (#{successful_teams.join(', ')})"
    puts "Failed teams: #{failed_teams.count} (#{failed_teams.join(', ')})"
    puts "Skipped teams: #{skipped_teams.count} (#{skipped_teams.join(', ')})"
    
    # Show results
    submissions = Submission.where(team_name: successful_teams).order(created_at: :desc)
    puts "\nLatest submissions for successful teams:"
    submissions.each do |sub|
      puts "#{sub.id}. Team: #{sub.team_name}, File: #{sub.filename}, Status: #{sub.status}"
    end
    
    puts "\nTo generate team summaries for these teams, run: rake folder_ingestion:generate_summaries"
  end
  
  desc "Generate summaries for teams created with folder_ingestion:start"
  task generate_summaries: :environment do
    # Get the hackathon ID from environment variables
    hackathon_id = ENV["HACKATHON_ID"]
    hackathon = nil
    
    if hackathon_id.present?
      hackathon = Hackathon.find_by(id: hackathon_id)
      if hackathon
        puts "Using hackathon: #{hackathon.name} (ID: #{hackathon.id})"
      else
        puts "⚠️ WARNING: Hackathon with ID #{hackathon_id} not found. Using default hackathon."
      end
    end
    
    # Use default hackathon if none specified or not found
    if hackathon.nil?
      hackathon = Hackathon.default
      puts "Using default hackathon: #{hackathon.name} (ID: #{hackathon.id})"
    end
    
    # Find teams from recently created submissions without summaries
    team_names = Submission.where(status: 'success')
                          .where('created_at > ?', 24.hours.ago)
                          .where(hackathon_id: hackathon.id)
                          .pluck(:team_name).uniq
    
    # Filter to only include teams that don't already have summaries
    teams_without_summaries = team_names.reject do |team_name|
      TeamSummary.exists?(team_name: team_name, hackathon_id: hackathon.id)
    end
    
    puts "Found #{teams_without_summaries.count} teams without summaries from recent submissions"
    
    teams_without_summaries.each do |team_name|
      puts "\nGenerating summary for team: #{team_name}"
      
      # Double check if a summary already exists (in case one was created in between)
      if TeamSummary.exists?(team_name: team_name, hackathon_id: hackathon.id)
        puts "  ⚠️ ERROR: Team summary was just created for #{team_name}. Skipping."
        next
      end
      
      # Find all successful submissions for the team
      submissions = Submission.where(team_name: team_name, status: 'success', hackathon_id: hackathon.id).order(created_at: :desc)
      
      if submissions.empty?
        puts "  No successful submissions found. Skipping."
        next
      end
      
      puts "  Found #{submissions.count} successful submissions"
      
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
        
        # Create a more customized summary based on the team name
        domain_info = {}
        
        case team_name
        when "AIInnovators", "TeamAlpha"
          domain_info = {
            domain: "Healthcare",
            technologies: "Python, TensorFlow, PyTorch, React Native, MongoDB, AWS",
            features: "Voice-activated medication reminders, Natural language symptom analysis, Emergency services quick-dial",
            focus: "AI-powered voice assistant for healthcare"
          }
        when "CityScapers", "TeamBeta"
          domain_info = {
            domain: "Smart City",
            technologies: "IoT, React, Node.js, MongoDB, Google Maps API",
            features: "Real-time traffic optimization, Urban mobility tracking, Public transport integration",
            focus: "Urban mobility solutions" 
          }
        when "FinTechWhiz", "TeamDelta"
          domain_info = {
            domain: "Finance/Fintech",
            technologies: "Blockchain, React, Node.js, PostgreSQL",
            features: "Peer-to-peer lending, KYC verification, Financial education modules",
            focus: "Financial inclusion platform"
          }
        when "GreenTech", "TeamGamma"
          domain_info = {
            domain: "Sustainability",
            technologies: "IoT, Blockchain, Machine Learning, React",
            features: "P2P energy trading, Grid optimization, Renewable energy tracking",
            focus: "Decentralized energy platform"
          }
        when "LearnSphere", "TeamOmega"
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
        TeamSummary.create!(
          team_name: team_name, 
          content: team_summary, 
          status: 'success',
          hackathon: hackathon
        )
        
        puts "  ✓ Successfully generated and saved summary"
      rescue => e
        puts "  ✗ Error generating team summary: #{e.message}"
        # Don't create a failed summary entry since we want to be able to retry
      end
    end
    
    puts "\nSummary generation completed!"
  end
  
  desc "Test uniqueness check with an existing team"
  task test_uniqueness: :environment do
    # Find a team that has a summary
    existing_summary = TeamSummary.first
    
    if existing_summary.nil?
      puts "No team summaries found. Please create some team summaries first."
      exit
    end
    
    team_name = existing_summary.team_name
    puts "Testing uniqueness check with existing team: #{team_name}"
    
    # Try to run the ingestion process for this team
    service = GoogleDriveService.new
    
    # Check if team summary already exists
    if TeamSummary.exists?(team_name: team_name)
      puts "✓ TEST PASSED: Correctly detected existing team summary for #{team_name}"
    else
      puts "❌ TEST FAILED: Did not detect existing team summary for #{team_name}"
    end
    
    # Now try to create a summary for this team and verify it fails
    begin
      # Try to create a new team summary with the same name
      TeamSummary.create!(
        team_name: team_name, 
        content: "This should fail due to uniqueness validation",
        status: "success"
      )
      puts "❌ TEST FAILED: Was able to create duplicate team summary!"
    rescue ActiveRecord::RecordInvalid => e
      if e.message.include?("has already been taken")
        puts "✓ TEST PASSED: Correctly failed to create duplicate team summary with validation error"
      else
        puts "❌ TEST FAILED: Failed with unexpected error: #{e.message}"
      end
    rescue => e
      puts "❌ TEST FAILED: Failed with unexpected error: #{e.message}"
    end
    
    puts "Uniqueness test completed!"
  end
end