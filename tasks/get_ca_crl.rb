#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'json'

begin
  content = File.read('/etc/puppetlabs/puppet/ssl/ca/ca_crl.pem')

  result = {
    'ca_crl' => content,
  }

  puts result.to_json
end
