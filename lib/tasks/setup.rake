namespace :setup do
  desc "Create default hackathon if none exists"
  task create_default_hackathon: :environment do
    if Hackathon.count == 0
      hackathon = Hackathon.create!(
        name: "Metathon 2025",
        description: "Default hackathon for document ingestion",
        status: "active",
        start_date: Date.today,
        end_date: Date.today + 30.days
      )
      puts "✅ Created default hackathon: #{hackathon.name} (ID: #{hackathon.id})"
    else
      puts "ℹ️ Default hackathon already exists. No action taken."
      puts "Current hackathons:"
      Hackathon.all.each do |h|
        puts "  - #{h.name} (ID: #{h.id}, Status: #{h.status})"
      end
    end
  end

  desc "Create a new hackathon"
  task :create_new_hackathon, [ :name ] => :environment do |_, args|
    name = args[:name] || "Metathon #{Date.today.year + 1}"

    hackathon = Hackathon.create!(
      name: name,
      description: "Hackathon for document ingestion",
      status: "active",
      start_date: Date.today,
      end_date: Date.today + 30.days
    )

    puts "✅ Created new hackathon: #{hackathon.name} (ID: #{hackathon.id})"
    puts "You can now use this ID in the frontend to select this hackathon"
  end

  desc "List all hackathons"
  task list_hackathons: :environment do
    hackathons = Hackathon.all.order(created_at: :desc)

    if hackathons.empty?
      puts "No hackathons found in the database"
    else
      puts "Hackathons in the database:"
      hackathons.each do |h|
        puts "- ID: #{h.id}, Name: #{h.name}, Status: #{h.status}, Created: #{h.created_at.strftime('%Y-%m-%d')}"
        puts "  Submissions: #{h.submissions.count}"
      end
    end
  end

  desc "Setup everything for development environment"
  task dev_setup: :environment do
    # Create default hackathon
    Rake::Task["setup:create_default_hackathon"].invoke

    # Create test data
    if Hackathon.count > 0 && TeamSummary.count == 0
      puts "🚀 Creating test data..."
      Rake::Task["test_data:generate_all_demo_data"].invoke
      puts "✅ Development environment setup complete!"
    end
  end
end
