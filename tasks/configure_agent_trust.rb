#!/opt/puppetlabs/puppet/bin/ruby

require 'puppet'
require 'puppet/face'
require 'json'

# The server parameter is either passed through STDIN in JSON object format, or
# is the first argument to the script.
server = ARGV[0] || JSON.parse(STDIN.read)['server']

raise 'Must provide server argument!' if server.nil?

Puppet.initialize_settings

uri = URI("https://#{server}:8140")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
http.start
ca  = http.get('/puppet-ca/v1/certificate/ca').body
crl = http.get('/puppet-ca/v1/certificate_revocation_list/ca').body
http.finish

crl_path = Puppet.settings['hostcrl']
ca_path  = Puppet.settings['localcacert']

File.write(ca_path, ca)
File.write(crl_path, crl)

if Puppet.version.split('.').first.to_i < 6
  Puppet::Face['config', '0.0.1'].set('certificate_revocation', 'leaf', section: 'main')
end
