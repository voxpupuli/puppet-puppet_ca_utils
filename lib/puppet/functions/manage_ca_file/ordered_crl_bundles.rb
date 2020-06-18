# frozen_string_literal: true

require 'net/http'
require 'openssl'

Puppet::Functions.create_function(:'manage_ca_file::ordered_crl_bundles') do
  dispatch :ordered_crl_bundles do
    param 'Hash',   :certs_by_name
    param 'String', :crl_bundle
  end

  def ordered_crl_bundles(certs_by_name, crl_bundle)
    crl_scan = /-----BEGIN X509 CRL-----(?:.|\n)+?-----END X509 CRL-----/
    crls = crl_bundle.scan(crl_scan)
                     .map { |crl| OpenSSL::X509::CRL.new(crl) }

    certs_by_name.map do |name,cert_text|
      cert = OpenSSL::X509::Certificate.new(cert_text)
      ordered_crls = crls.dup
      unless (idx = ordered_crls.find_index { |crl| crl.issuer == cert.issuer })
        raise "missing crl for #{cert}" 
      end
      [name,
       ordered_crls.unshift(ordered_crls.delete_at(idx))
                   .map { |crl| crl.to_pem }
                   .join('')
                   .encode('ascii')]
    end.to_h
  end
end
