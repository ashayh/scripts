#!/usr/bin/env ruby

require 'colorize'
require 'dnsruby'
require 'trollop'

opts = Trollop::options do
    opt :domain, 'Domain to scan', :required => true, :type => String
end

# Create a new resolver. Using TCP as it's needed for zone transfers
r = Dnsruby::Resolver.new( :use_tcp => true )

# Gathering information
puts "Fetching DNS servers for: #{opts[:domain]}".light_green
begin
    NS_SERVERS = []
    r.query("#{opts[:domain]}", 'NS').answer.each do |ns|
        NS_SERVERS << ns.nsdname.to_s
    end
rescue Dnsruby::NXDomain
    puts 'Invalid domain. Aborting.'.red
    exit 1
end

# Try to do a zone transfer on each DNS servers
z = ''
NS_SERVERS.sort.each do |ns|
    puts "Attempting a zone transfer on #{ns}: "
    r.nameserver = ns
    begin
        z = r.query("#{opts[:domain]}", 'AXFR')
        puts "Wow ... that worked. Really?!?!".light_yellow
    rescue Dnsruby::Refused
            puts "Server refused request".red
    end
end
puts ''
puts 'Saving zone information for later use'.light_green if not z.answer.empty?
puts ''
puts "WARNING: The script at this point doesn't check if there's a difference
between each zone data. It might at some point in the future.".red if not z.answer.empty?

# Start scanning hosts
if z.answer
else
end
