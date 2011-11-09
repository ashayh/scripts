#!/usr/bin/env ruby
#
# Dump tool that crawls a base URL, creates an array
# of all found URLs, then tries to open the page while
# appending a ' character in the URL. If then looks at
# the returned page to check if there's a MySQL error.
#
# NOTE: This tool is dumb, it doesn't throttle itself.
#
# Requires MongoDB to store the pages during the crawl.
#
# License: GPLv2

require 'rubygems'
require 'anemone'
require 'net/http'
require 'trollop'

opts = Trollop::options do
  opt :site, 'Site to crawl', :required => true, :type => String
end

if not opts[:site] =~ /^http/
  base_url = 'http://' + opts[:site]
else
  base_url = opts[:site]
end

# Generate the list of URLs to test
puts 'Crawling site'
Anemone.crawl(base_url) do |a|
  a.storage = Anemone::Storage.MongoDB
  URLS = []
  a.on_every_page do |p|
    if p.html?
      URLS << p.url.to_s
    end
  end
end

# Blind testing by modifying the URLS to append '
# and check if the returned page contains a MySQL error.
puts 'Testing each URL'
URLS.each do |u|
  if u =~ /\?/
    new_url = u.gsub(/=/, "='")
    d = Net::HTTP.get(URI(new_url))
    if d =~ /You have an error in your SQL syntax/i
      puts "#{u}: might be injectable!"
    elsif d =~ /supplied argument is not a valid MySQL result/i
      puts "#{u}: might be injectable!"
    end
  end
end
