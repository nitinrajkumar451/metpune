namespace :debug do
  desc "Print IngestDocumentsJob logs"
  task check_job: :environment do
    job = IngestDocumentsJob.new
    begin
      puts "Starting job execution..."
      job.perform
      puts "Job completed successfully!"
    rescue => e
      puts "JOB ERROR: #{e.class} - #{e.message}"
      puts e.backtrace.join("\n")
    end
  end

  desc "Check job queue status"
  task queue_status: :environment do
    puts "Active Job Adapter: #{Rails.application.config.active_job.queue_adapter.inspect}"
    puts "Pending submissions: #{Submission.pending.count}"
    puts "Processing submissions: #{Submission.processing.count}"
    puts "Successful submissions: #{Submission.success.count}"
    puts "Failed submissions: #{Submission.failed.count}"
  end
  
  desc "Show recent submissions"
  task show_submissions: :environment do
    puts "Recent submissions:"
    Submission.order(created_at: :desc).limit(10).each do |submission|
      puts "ID: #{submission.id}, Team: #{submission.team_name}, File: #{submission.filename}, Type: #{submission.file_type}, Status: #{submission.status}"
      puts "  Raw text: #{submission.raw_text ? submission.raw_text[0..50] + '...' : 'nil'}"
      puts ""
    end
  end
end