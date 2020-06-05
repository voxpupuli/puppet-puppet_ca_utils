#!/opt/puppetlabs/puppet/bin/ruby

require 'open3'
require 'openssl'

require_relative '../../ruby_task_helper/files/task_helper.rb'

# Example task that is based on the ruby_task_helper
class RemoteCRLContent < TaskHelper
  def task(name: nil, **kwargs)
    remote_cmd = ['curl', '-k', '-s', "https://#{kwargs[:ca_hostname]}:8140/puppet-ca/v1/certificate_revocation_list/ca"]
    stdout, stderr, status = Open3.capture3(*remote_cmd) # rubocop:disable Lint/UselessAssignment
    raise Puppet::Error, _("stderr: ' %{stderr}') % { stderr: stderr }") if status != 0
    
    next_crl = OpenSSL::X509::CRL.new(stdout)

    authorityKeyIdentifier_matcher = %r{(keyid.+),}.match(next_crl.extensions()[0].to_s())

    authorityKeyIdentifier = authorityKeyIdentifier_matcher[1]
    
    {
      authorityKeyIdentifier: authorityKeyIdentifier,
      output: stdout
    }   
  end
end

RemoteCRLContent.run if $PROGRAM_NAME == __FILE__
