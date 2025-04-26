#!/usr/bin/env ruby
require_relative 'config/environment'

# Check the blogs
puts "Team Blogs:"
TeamBlog.all.each do |blog|
  puts "#{blog.team_name}: Status: #{blog.status}, Content length: #{blog.content ? blog.content.length : 0}"
end