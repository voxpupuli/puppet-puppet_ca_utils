#!/opt/puppetlabs/puppet/bin/ruby

require 'open3'
require 'openssl'
require 'puppet'

require_relative '../../ruby_task_helper/files/task_helper.rb'

# Example task that is based on the ruby_task_helper
class SyncCAContent < TaskHelper
  def task(name: nil, **kwargs)
    all_crls = []

    # Get remote ca
    cmd = ['curl', '-k', '-s', "https://#{kwargs[:ca_hostname]}:8140/puppet-ca/v1/certificate/ca"]
    stdout, stderr, status = Open3.capture3(*cmd)
    raise Puppet::Error, _("{ stderr: #{stderr} }") if status != 0

    # Read current ca_crl file
    local_cas_all = File.read('/etc/puppetlabs/puppet/ssl/certs/ca.pem')

    # Split up certs
    delimeter = "\n-----END CERTIFICATE-----\n"

    local_ca_strings = local_cas_all.split(delimeter)

    # Get all certs as ruby CRL objects
    local_ca_strings.each do |local_ca|
      all_crls << OpenSSL::X509::Certificate.new("#{local_ca}\n-----END CERTIFICATE-----\n-")
    end

    remote_crls_strings = stdout.split(delimeter)

    # Get all certs as ruby CRL objects
    remote_crls_strings.each do |remote_crl|
      all_crls << OpenSSL::X509::Certificate.new("#{remote_crl}\n-----END CERTIFICATE-----\n")
    end

    # Remove duplicates
    all_crls.uniq! { |crl| crl.to_pem }

    # # Get back pem representations
    # unique_crls = all_crls.select { |crl|
    #   crl.to_pem()
    # }

    # # Rebuild CRL and write it back
    new_ca = all_crls.join('')

    # puts "New ca #{new_ca}"

    # result = File.write('/etc/puppetlabs/puppet/ssl/certs/ca.pem', new_ca)

    { ca: new_ca }
  end
end

SyncCAContent.run if $PROGRAM_NAME == __FILE__
