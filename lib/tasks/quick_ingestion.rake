namespace :quick_ingestion do
  desc "Run a quick ingestion test with uniqueness check on a single team"
  task start: :environment do
    puts "Starting quick ingestion test with uniqueness check..."

    # Create timestamps for unique team names
    timestamp = Time.now.strftime("%m%d_%H%M")

    # Only process the first team folder (TeamAlpha in this case)
    service = GoogleDriveService.new
    team_folders = service.list_team_folders

    if team_folders.empty?
      puts "No team folders found. Exiting."
      exit
    end

    # Only process the first team
    original_team_name = team_folders.first
    team_name = "#{original_team_name}_#{timestamp}"

    puts "Testing with team: #{team_name} (original: #{original_team_name})"

    # Check if team summary already exists
    existing_summary = TeamSummary.find_by(team_name: team_name)
    if existing_summary
      puts "⚠️ ERROR: Team summary already exists for #{team_name}. Exiting."
      exit
    end

    # Process only the first file from this team
    files = service.list_team_files(original_team_name)

    if files.empty?
      puts "No files found for team #{original_team_name}. Exiting."
      exit
    end

    file = files.first
    puts "Processing file: #{file[:name]}"

    # Extract project name from path
    path_parts = file[:path].split("/")
    project = path_parts.length >= 2 ? path_parts[1] : "Default"

    # Create submission record
    submission = Submission.new(
      team_name: team_name,
      filename: file[:name],
      file_type: "pdf",
      project: project,
      source_url: Rails.root.join("tmp/mock_drive", file[:path]).to_s,
      status: "processing"
    )

    # Save without validation to ensure it goes through
    submission.save(validate: false)

    # Process the submission
    begin
      # Read the file directly from disk
      file_path = Rails.root.join("tmp/mock_drive", file[:path])
      file_content = File.binread(file_path)

      # Check if it's a valid PDF
      if !file_content.start_with?("%PDF")
        puts "⚠️ Warning: #{file[:name]} doesn't appear to be a valid PDF"
      end

      # Instead of using AI to generate a summary (which takes time),
      # let's use a mock summary for a quick test
      summary = "This is a mock summary for #{file[:name]} to test the quick ingestion task."

      # Update the submission with the summary
      submission.update!(
        summary: summary,
        status: "success"
      )

      puts "✓ Successfully processed #{file[:name]}"

      # Create a simple team summary
      team_summary = TeamSummary.new(
        team_name: team_name,
        content: "# Quick Test Summary for #{team_name}\n\nThis is a test summary created by the quick_ingestion:start task.",
        status: "success"
      )

      # Save without validation
      team_summary.save(validate: false)

      puts "✓ Successfully created team summary for #{team_name}"

    rescue => e
      puts "✗ Error during quick ingestion test: #{e.message}"
      submission.update!(
        status: "failed",
        summary: "Error: #{e.message}"
      )
    end

    puts "Quick ingestion test completed!"
    puts "Created test submission and team summary for: #{team_name}"
    puts "You can now test that trying to create this team again will fail with an error."
  end

  desc "Test uniqueness check - should fail for existing team"
  task test_uniqueness: :environment do
    # Get the most recently created team summary
    latest_summary = TeamSummary.order(created_at: :desc).first

    if latest_summary.nil?
      puts "No team summaries found. Please run quick_ingestion:start first."
      exit
    end

    team_name = latest_summary.team_name
    puts "Testing uniqueness check with existing team: #{team_name}"

    # Try to create a new team summary with the same name
    begin
      new_summary = TeamSummary.create!(
        team_name: team_name,
        content: "This should fail due to uniqueness check",
        status: "success"
      )
      puts "❌ TEST FAILED: Was able to create duplicate team summary!"
    rescue => e
      puts "✓ TEST PASSED: Correctly failed to create duplicate team summary: #{e.message}"
    end

    puts "Uniqueness test completed!"
  end
end
