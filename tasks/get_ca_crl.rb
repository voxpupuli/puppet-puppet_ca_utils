#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'json'

begin
  params  = JSON.parse(STDIN.read)
  content = File.read('/etc/puppetlabs/puppet/ssl/ca/ca_crl.pem')

  result = {
    'ca_crl' => content,
  }

  puts result.to_json
end
