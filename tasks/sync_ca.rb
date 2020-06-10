#!/opt/puppetlabs/puppet/bin/ruby

require 'open3'
require 'openssl'
require 'puppet'

require_relative '../../ruby_task_helper/files/task_helper.rb'

# Example task that is based on the ruby_task_helper
class SyncCAContent < TaskHelper
  def task(name: nil, **kwargs)
    all_crts = []

    # Get remote ca
    cmd = ['curl', '-k', '-s', "https://#{kwargs[:ca_hostname]}:8140/puppet-ca/v1/certificate/ca"]
    stdout, stderr, status = Open3.capture3(*cmd)
    raise Puppet::Error, _("{ stderr: #{stderr} }") if status != 0

    # Read current ca_crt file
    local_cas_all = File.read('/etc/puppetlabs/puppet/ssl/certs/ca.pem')

    # Split up certs
    delimeter = "\n-----END CERTIFICATE-----\n"

    local_ca_strings = local_cas_all.split(delimeter)

    # Get all certs as ruby CRL objects
    local_ca_strings.each do |local_ca|
      all_crts << OpenSSL::X509::Certificate.new("#{local_ca}\n-----END CERTIFICATE-----\n-")
    end

    remote_crts_strings = stdout.split(delimeter)

    # Get all certs as ruby CRL objects
    remote_crts_strings.each do |remote_crt|
      all_crts << OpenSSL::X509::Certificate.new("#{remote_crt}\n-----END CERTIFICATE-----\n")
    end

    # Remove duplicates
    all_crts.uniq! { |crt| crt.to_pem }

    # # Get back pem representations
    # unique_crts = all_crts.select { |crt|
    #   crt.to_pem()
    # }

    # # Rebuild CRL and write it back
    new_ca = all_crts.join('')

    # puts "New ca #{new_ca}"

    # result = File.write('/etc/puppetlabs/puppet/ssl/certs/ca.pem', new_ca)

    { ca: new_ca }
  end
end

SyncCAContent.run if $PROGRAM_NAME == __FILE__
