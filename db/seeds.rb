# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default hackathon if none exists
puts "Checking for existing hackathons..."
if Hackathon.count == 0
  puts "Creating default hackathon..."

  default_hackathon = Hackathon.create!(
    name: "Metathon 2025",
    description: "The inaugural Metathon hackathon focused on AI and document processing.",
    start_date: Date.new(2025, 4, 1),
    end_date: Date.new(2025, 4, 30),
    status: "active"
  )

  puts "Created default hackathon: #{default_hackathon.name} (ID: #{default_hackathon.id})"
else
  puts "Default hackathon already exists. Using existing hackathon."
  default_hackathon = Hackathon.first
  puts "Using hackathon: #{default_hackathon.name} (ID: #{default_hackathon.id})"
end

# Create default judging criteria
puts "Creating default judging criteria..."
judging_criteria = [
  {
    name: "Innovation",
    description: "How innovative is the solution? Does it present new ideas or approaches?",
    weight: 0.25
  },
  {
    name: "Technical Execution",
    description: "How well is the project implemented technically? Is the code well-structured?",
    weight: 0.25
  },
  {
    name: "Impact",
    description: "What is the potential impact of this solution? Does it solve a significant problem?",
    weight: 0.20
  },
  {
    name: "Presentation Quality",
    description: "How clear and effective is the presentation of the project? Is it easy to understand?",
    weight: 0.15
  },
  {
    name: "Completeness",
    description: "How complete is the project? Are all features implemented as described?",
    weight: 0.15
  }
]

judging_criteria.each do |criteria|
  JudgingCriterion.find_or_create_by!(name: criteria[:name], hackathon_id: default_hackathon.id) do |criterion|
    criterion.description = criteria[:description]
    criterion.weight = criteria[:weight]
    criterion.hackathon_id = default_hackathon.id
  end
end

puts "Created #{JudgingCriterion.count} judging criteria"

# Create dummy team data if in development environment
if Rails.env.development?
  puts "Creating sample team data for development..."

  # Create team summaries
  team_names = [ "TeamAlpha", "TeamBeta", "TeamGamma", "TeamDelta", "TeamOmega" ]

  team_names.each do |team_name|
    unless TeamSummary.exists?(team_name: team_name, hackathon_id: default_hackathon.id)
      # Create team summary with appropriate domain focus based on team name
      domain_info = case team_name
      when "TeamAlpha"
        {
          domain: "Healthcare",
          technologies: "Python, TensorFlow, PyTorch, React Native, MongoDB, AWS",
          features: "Voice-activated medication reminders, Natural language symptom analysis, Emergency services quick-dial",
          focus: "AI-powered voice assistant for healthcare"
        }
      when "TeamBeta"
        {
          domain: "Smart City",
          technologies: "IoT, React, Node.js, MongoDB, Google Maps API",
          features: "Real-time traffic optimization, Urban mobility tracking, Public transport integration",
          focus: "Urban mobility solutions"
        }
      when "TeamGamma"
        {
          domain: "Sustainability",
          technologies: "IoT, Blockchain, Machine Learning, React",
          features: "P2P energy trading, Grid optimization, Renewable energy tracking",
          focus: "Decentralized energy platform"
        }
      when "TeamDelta"
        {
          domain: "Finance/Fintech",
          technologies: "Blockchain, React, Node.js, PostgreSQL",
          features: "Peer-to-peer lending, KYC verification, Financial education modules",
          focus: "Financial inclusion platform"
        }
      when "TeamOmega"
        {
          domain: "Education",
          technologies: "Node.js, Python, React Native, MongoDB, GraphQL",
          features: "Cognitive profiling, Personalized learning paths, Knowledge state modeling",
          focus: "Adaptive learning platform"
        }
      end

      # Generate team summary content
      team_summary_content = <<~SUMMARY
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

      # Create the team summary
      TeamSummary.create!(
        team_name: team_name,
        content: team_summary_content,
        status: "success",
        hackathon_id: default_hackathon.id
      )

      puts "Created team summary for #{team_name}"
    end
  end

  # Create team evaluations with realistic scores
  team_names.each do |team_name|
    unless TeamEvaluation.exists?(team_name: team_name, hackathon_id: default_hackathon.id)
      # Generate varied scores based on team name
      scores = {}
      total_weighted_score = 0
      total_weight = 0

      # Create unique scores for each team and criterion
      JudgingCriterion.where(hackathon_id: default_hackathon.id).each do |criterion|
        # Generate a base score with some randomness depending on team name
        base_score = case team_name
        when "TeamAlpha" then 4.6
        when "TeamBeta" then 4.3
        when "TeamGamma" then 4.5
        when "TeamDelta" then 4.1
        when "TeamOmega" then 4.7
        else 4.0
        end

        # Add some per-criterion variation
        variation = case criterion.name
        when "Innovation"
          team_name == "TeamAlpha" || team_name == "TeamGamma" ? 0.2 : -0.1
        when "Technical Execution"
          team_name == "TeamBeta" || team_name == "TeamDelta" ? 0.3 : 0.1
        when "Impact"
          team_name == "TeamOmega" || team_name == "TeamAlpha" ? 0.1 : -0.2
        when "Presentation Quality"
          team_name == "TeamGamma" ? 0.4 : 0.0
        when "Completeness"
          team_name == "TeamBeta" || team_name == "TeamOmega" ? 0.2 : -0.1
        else 0.0
        end

        # Calculate final score (between 3.5 and 5.0, rounded to 1 decimal)
        score = [ (base_score + variation).round(1), 5.0 ].min
        score = [ score, 3.5 ].max

        # Generate feedback based on score
        feedback = if score >= 4.5
          "Exceptional performance in this area. The team demonstrated outstanding #{criterion.name.downcase} with remarkable attention to detail and execution."
        elsif score >= 4.0
          "Excellent work in this criterion. The team showed strong capabilities and delivered high-quality results."
        elsif score >= 3.5
          "Good performance with room for enhancement. The team met expectations but could further develop this aspect."
        else
          "Satisfactory work in this area. There is significant room for improvement in future iterations."
        end

        scores[criterion.name] = {
          "score" => score,
          "weight" => criterion.weight,
          "feedback" => feedback
        }

        total_weighted_score += score * criterion.weight
        total_weight += criterion.weight
      end

      average_score = (total_weighted_score / [ total_weight, 0.01 ].max).round(2)

      # Generate team-specific comments
      comments = case team_name
      when "TeamAlpha"
        "TeamAlpha's healthcare voice assistant demonstrates exceptional innovation and technical implementation. The solution addresses critical needs in patient care with a well-designed voice interface and robust backend services. Future iterations could focus on expanding language support and healthcare provider integrations."
      when "TeamBeta"
        "TeamBeta's urban mobility platform shows excellent technical execution and real-world impact potential. The integration of IoT devices with transit data creates a compelling solution for smart city applications. Additional user testing in diverse urban environments would strengthen the solution further."
      when "TeamGamma"
        "TeamGamma's decentralized energy platform demonstrates innovative use of blockchain technology with strong technical implementation. The peer-to-peer trading system addresses key challenges in renewable energy distribution. Further development of user onboarding processes would enhance adoption potential."
      when "TeamDelta"
        "TeamDelta's financial inclusion platform shows strong technical execution with meaningful societal impact. The combination of secure transactions and educational modules creates a comprehensive solution. Enhancing the mobile experience and adding offline capabilities could further increase accessibility."
      when "TeamOmega"
        "TeamOmega's adaptive learning system demonstrates exceptional technical sophistication and innovative approaches to personalized education. The cognitive profiling and knowledge mapping show deep domain understanding. Expanding content areas and adding instructor dashboards would create additional value."
      else
        "The team delivered a solid project with good technical execution and innovation. There are opportunities to enhance user experience and expand feature coverage in future iterations."
      end

      # Create the team evaluation
      TeamEvaluation.create!(
        team_name: team_name,
        scores: scores,
        total_score: average_score,
        comments: comments,
        status: "success",
        hackathon_id: default_hackathon.id
      )

      puts "Created team evaluation for #{team_name} with score: #{average_score}"
    end
  end

  # Create hackathon insights
  unless HackathonInsight.exists?(hackathon_id: default_hackathon.id)
    # Generate structured insights JSON
    insights_data = {
      programming_languages: {
        description: "Analysis of programming languages used across projects",
        data: [
          { name: "JavaScript", count: 12, percentage: 80 },
          { name: "Python", count: 8, percentage: 53 },
          { name: "TypeScript", count: 7, percentage: 47 },
          { name: "Ruby", count: 6, percentage: 40 },
          { name: "Java", count: 4, percentage: 27 }
        ],
        insights: "JavaScript continues to dominate as the most widely used language, appearing in 80% of projects. Python follows closely, particularly in projects with AI components. TypeScript adoption is growing rapidly, indicating teams' preference for type safety in frontend development."
      },
      ai_tools: {
        description: "Analysis of AI tools and frameworks used",
        data: [
          { name: "TensorFlow", count: 7, percentage: 47 },
          { name: "OpenAI", count: 6, percentage: 40 },
          { name: "Claude/Anthropic", count: 5, percentage: 33 },
          { name: "PyTorch", count: 4, percentage: 27 },
          { name: "Hugging Face", count: 3, percentage: 20 }
        ],
        insights: "TensorFlow leads as the most popular AI framework, commonly used for custom model development. OpenAI's APIs were frequently utilized for text generation and summarization tasks. Claude/Anthropic APIs were particularly favored for document understanding and complex prompt engineering scenarios."
      },
      coherent_ideas: {
        description: "Recurring themes and coherent project ideas",
        list: [
          "Smart healthcare monitoring using AI for early diagnosis and treatment recommendations",
          "Document processing pipelines with multi-level summarization capabilities",
          "Sustainability platforms for tracking and optimizing resource usage",
          "Educational technology solutions with adaptive learning features",
          "Financial inclusion tools targeting underserved communities"
        ],
        insights: "Health tech and document processing emerged as the dominant themes across projects. Teams demonstrated particular interest in multi-level analysis systems that could process information at various granularities. Sustainability-focused projects showed the most interdisciplinary approach, combining IoT, data visualization, and predictive analytics."
      },
      common_wins: {
        description: "Achievements and successes observed across teams",
        list: [
          "Strong technical implementations with well-architected systems and clean code organization",
          "Effective use of modern development practices including CI/CD, testing, and documentation",
          "Creative UI/UX designs that made complex data accessible and intuitive",
          "Successful integration of multiple AI services into coherent workflows",
          "Implementations that addressed real-world problems with practical solutions"
        ],
        insights: "Teams that performed well typically demonstrated excellence in both technical implementation and user experience design. Clean architecture patterns were evident in the most successful projects, with clear separation of concerns. Documentation quality correlated strongly with overall project success, especially for more complex solutions."
      },
      common_pitfalls: {
        description: "Challenges and obstacles faced by teams",
        list: [
          "Scope too ambitious for hackathon timeframe, leading to partially implemented features",
          "Insufficient error handling in AI components causing cascade failures",
          "Over-reliance on external APIs without fallback mechanisms",
          "Performance issues when processing large documents or datasets",
          "Challenges in effective UI/UX design for complex data visualization"
        ],
        insights: "The most common pitfall was underestimating the complexity of AI integration, particularly when dealing with multiple models or services. Teams frequently struggled with proper error handling for AI components, often assuming ideal response patterns. Performance optimization was frequently deprioritized due to time constraints."
      },
      innovative_ideas: {
        description: "Standout innovative approaches",
        list: [
          "Team Alpha's novel approach to document streaming for real-time collaborative annotation",
          "Team Beta's multi-modal understanding system combining text, image, and layout analysis",
          "Team Gamma's hierarchical summarization system maintaining context across levels",
          "Team Delta's innovative caching strategy for optimizing AI API usage",
          "Team Omega's hybrid local/cloud processing model for sensitive documents"
        ],
        insights: "The most innovative solutions typically combined established techniques in novel ways rather than developing entirely new algorithms. Cross-domain approaches, particularly those combining NLP, computer vision, and structured data analysis, produced exceptionally innovative results. Teams that invested time in thoughtful prompt engineering for AI models achieved significantly better results."
      },
      executive_summary: "This analysis examines patterns and trends across teams participating in Metathon 2025. Overall, we observed a strong focus on AI-powered solutions, particularly in document processing and healthcare domains. Most teams utilized modern web frameworks combined with AI services, with JavaScript and TensorFlow being particularly popular choices. Common challenges included API integration issues and balancing feature scope with time constraints. Innovation was highest in the application of AI for specialized document understanding and in creating intuitive user experiences for complex data.",
      recommendations: "For future hackathons, we recommend: 1) Providing specialized AI access to allow teams to focus on innovation rather than API limits, 2) Encouraging cross-domain collaboration as teams with diverse skills produced more complete solutions, 3) Emphasizing user testing since projects with user feedback iterations showed better overall results, 4) Offering starter templates with authentication and basic API setups so teams can focus on core innovation, and 5) Considering longer hackathon durations as complex AI applications benefit from more iteration time."
    }.to_json

    # Create the hackathon insights
    HackathonInsight.create!(
      content: insights_data,
      status: "success",
      hackathon_id: default_hackathon.id
    )

    puts "Created hackathon insights"
  end

  puts "Completed creating sample data for development environment"
end

puts "Seed data creation complete!"
