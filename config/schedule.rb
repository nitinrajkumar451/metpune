# Use this file to easily define all of your cron jobs.
#
# Learn more: http://github.com/javan/whenever

# Set the environment
set :environment, ENV['RAILS_ENV'] || 'development'
set :output, "#{path}/log/cron.log"

# Every 10 minutes, check for team summaries that need blogs
every 10.minutes do
  rake "auto_blogs:generate"
end

# Every 15 minutes, check for teams that need summaries and blogs
every 15.minutes do
  rake "auto_blogs:generate_all"
end

# Every 20 minutes, check for teams that need evaluation
every 20.minutes do
  rake "auto_blogs:evaluate"
end