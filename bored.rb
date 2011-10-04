#!/usr/bin/ruby -W0

require 'colorize'
require 'net/dns/resolver'
require 'socket'
require 'trollop'
require 'whois'

opts = Trollop::options do
    opt :domain, 'Domain to scan', :required => true, :type => String
end

# Validating domain thru WHOIS
begin
    if Whois.query(opts[:domain]).available?
        puts 'ERROR: Invalid domain'.red
        exit 1
    end
rescue Whois::ServerNotFound=>e
    puts "ERROR: #{e}".red
    exit 1
end

r = Net::DNS::Resolver.new
# Fetch DNS servers
NS_SERVERS = Hash.new
ns = r.query("#{opts[:domain]}", Net::DNS::NS)
ns.answer.each do |rr|
    n = rr.nsdname.chomp('.')
    NS_SERVERS[n] = IPSocket.getaddress(n)
end

# Fetch MX servers
MX_SERVERS = Hash.new
mx = r.mx("#{opts[:domain]}")
mx.each do |m|
    MX_SERVERS[m.exchange] = m.preference
end
