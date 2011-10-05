#!/usr/bin/env ruby

require 'colorize'
require 'dnsruby'
require 'socket'
require 'trollop'

opts = Trollop::options do
    opt :domain, 'Domain to scan', :required => true, :type => String
end
puts "Target domain: #{opts[:domain]}".light_blue

# Create a new resolver
r = Dnsruby::Resolver.new( :use_tcp => true )

# DNS servers
puts "*** Testing DNS servers ***".light_green
begin
    NS_SERVERS = Hash.new
    r.query("#{opts[:domain]}", 'NS').answer.each do |ns|
        NS_SERVERS[ns.nsdname.to_s] = IPSocket.getaddress(ns.nsdname.to_s)
    end
rescue Dnsruby::NXDomain
    puts 'Invalid domain. Aborting.'.red
    exit 1
end
z = ''
NS_SERVERS.sort.each do |ns|
    puts "#{ns[0]} ".light_yellow + "(#{ns[1]}):".light_blue
    puts "Attempting a zone transfer:"
    r.nameserver = ns
    begin
        z = r.query("#{opts[:domain]}", 'AXFR')
        puts "Wow ... that worked. Really?!?!\n".light_yellow
    rescue Dnsruby::Refused
            puts "Server refused request\n".red
    end
end
puts "\n"

# MX servers
puts "*** Testing MX servers ***".light_green
MX_SERVERS = Hash.new
r.query("#{opts[:domain]}", 'MX').answer.each do |mx|
    MX_SERVERS[mx.exchange.to_s] = mx.preference
end
MX_SERVERS.sort_by{ |k,v| v}.each do |mx|
    puts "#{mx[0]} ".downcase.light_yellow \
        + "(#{IPSocket.getaddress(mx[0])})".light_blue \
        + "(#{mx[1]}): \n".light_blue
end
puts "\n"
