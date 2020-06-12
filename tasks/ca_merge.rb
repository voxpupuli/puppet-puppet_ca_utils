#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'net/http'

# Bolt task using helper
class CAMerge < TaskHelper

  CERT_SCAN = /-----BEGIN CERTIFICATE-----(?:.|\n)+?-----END CERTIFICATE-----/
  CRL_SCAN = /-----BEGIN X509 CRL-----(?:.|\n)+?-----END X509 CRL-----/

  def task(ca_hostnames:, **kwargs)
    # Get the cert data from each CA
    ca_bundle = ca_hostnames.map { |host| get_ca_bundle(host).scan(CERT_SCAN) }
                            .flatten
                            .uniq
                            .join('')

    # Merge the arrays together, eliminating duplicates
    new_ca_bundle = (ca1_certs | ca2_certs).join('')

    # Get the crl data from each CA
    ca1_crl = get_crl_bundle(ca1_hostname).scan(CRL_SCAN)
    ca2_crl = get_crl_bundle(ca2_hostname).scan(CRL_SCAN)

    # Merge the CRLs together, newest copies of each, eliminating duplicates
    new_crl_bundle = (ca1_crl | ca2_crl).map { |crl| OpenSSL::X509::CRL.new(crl) }
                                        .group_by { |crl| crl.issuer.hash }
                                        .map { |_,crls| crls.max_by { |crl| crl.last_update } }
                                        .map { |crl| crl.to_pem }
                                        .join('')

    # Return the merged data
    { ca_bundle: new_ca_bundle,
      crl_bundle: new_crl_bundle }
  end

  def get_ca_bundle(hostname)
    uri = URI("https://#{hostname}:8140/puppet-ca/v1/certificate/ca")
    get(uri)
  end

  def get_crl_bundle(hostname)
    uri = URI("https://#{hostname}:8140/puppet-ca/v1/certificate_revocation_list/ca")
    get(uri)
  end

  def get(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.get(uri.path)
    response.body
  end
end

CAMerge.run if $PROGRAM_NAME == __FILE__
