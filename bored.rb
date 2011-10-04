#!/usr/bin/env ruby

require 'colorize'
require 'net/dns/resolver'
require 'socket'
require 'trollop'
require 'whois'

start_time = Time.now

opts = Trollop::options do
    opt :domain, 'Domain to scan', :required => true, :type => String
end

puts "Target domain: #{opts[:domain]}"
# Validating domain thru WHOIS
print 'Validating domain: ',
begin
    if Whois.query(opts[:domain]).available?
        puts 'ERROR: Invalid domain'.red
        exit 1
    end
rescue Whois::ServerNotFound=>e
    puts "ERROR: #{e}".red
    exit 1
rescue Timeout::Error=>e
    puts "ERROR: #{e}".red
    exit 1
end
print "done\n"

print "Fetching DNS information: "
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
print "done\n"

# Try to fetch zone
NS_SERVERS.each do |ns|
    print "Attempting to do a zone transfer on #{ns[0]}:",
    r.nameservers = ns[1]
    r.use_tcp = true
    z = r.axfr("#{opts[:domain]}")
    if not z.answer.empty?
        print "done (wow ... really?!?)\n"
        break
    end
    print "fail\n"
end

# Elapsed time
puts "Run time: #{Time.now - start_time} seconds"
