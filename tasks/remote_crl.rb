#!/opt/puppetlabs/puppet/bin/ruby

require 'open3'
require 'openssl'

require_relative '../../ruby_task_helper/files/task_helper.rb'

# Example task that is based on the ruby_task_helper
class RemoteCRLContent < TaskHelper
  def task(name: nil, **kwargs)
    keyid_array = []

    remote_cmd = ['curl', '-k', '-s', "https://#{kwargs[:ca_hostname]}:8140/puppet-ca/v1/certificate_revocation_list/ca"]
    stdout, stderr, status = Open3.capture3(*remote_cmd) # rubocop:disable Lint/UselessAssignment
    raise Puppet::Error, _("stderr: ' %{stderr}') % { stderr: stderr }") if status != 0

    delimeter = "\n-----END X509 CRL-----\n"

    local_crls = stdout.split(delimeter)

    local_crls.each do |local_crl|
      next_crl = OpenSSL::X509::CRL.new("#{local_crl}\n-----END X509 CRL-----")

      keyid_array << %r{(keyid.+),}.match(next_crl.extensions[0].to_s)[1]
    end

    {
      keyids: keyid_array,
      crl: stdout,
    }
  end
end

RemoteCRLContent.run if $PROGRAM_NAME == __FILE__
