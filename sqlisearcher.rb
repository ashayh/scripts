#!/usr/bin/env ruby
#
# This script crawls a base URL, looks inside each page for the
# POST method. If found, it will then try to do some SQL injection
# in the fields. It will then look for some MySQL error.
#
# Requires: MongoDB to store the pages. Only really useful for larger
# sites. No security needed for that either.
#
# License: GPLv2

require 'rubygems'
require 'colorize'
require 'anemone'
require 'trollop'

opts = Trollop::options do
  opt :site, 'Site to crawl', :required => true, :type => String
end

if not opts[:site] =~ /^http/
  base_url = 'http://' + opts[:site]
else
  base_url = opts[:site]
end

Anemone.crawl(base_url) do |a|
  a.storage = Anemone::Storage.MongoDB
  UNTESTED_URLS = []
  a.on_every_page do |p|
    begin
      p.doc.xpath('//form').each do |n|
	if n['method'] =~ /^post$/i
	  # Now that we have a testable URL, let's try
	  # some SQLi :)
	  puts p.url
	end
      end
    rescue NoMethodError
      UNTESTED_URLS << p.url.to_s
    end
  end
end

puts 'These URLs were not tested due to some error. Please review them manually:'.light_red
UNTESTED_URLS.each do |ut|
    puts ut.light_yellow
end
