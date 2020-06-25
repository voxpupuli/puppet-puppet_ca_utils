# frozen_string_literal: true

require 'net/http'
require 'openssl'

Puppet::Functions.create_function(:'manage_ca_file::ordered_crl_bundles') do
  dispatch :ordered_pems do
    param 'Hash',   :certs_by_name
    param 'String', :crl_bundle
  end

  def ordered_pems(certs_by_name, crl_bundle)
    crl_scan = %r{-----BEGIN X509 CRL-----(?:.|\n)+?-----END X509 CRL-----}
    crls = crl_bundle.scan(crl_scan).map { |crl| OpenSSL::X509::CRL.new(crl) }
    pem_by_name(certs_by_name, crls)
  end

  def pem_by_name(certs_by_name, x509_obj_array)
    certs_by_name.map { |name, cert_text|
      cert = OpenSSL::X509::Certificate.new(cert_text)
      ordered_obj_array = x509_obj_array.dup
      unless (idx = ordered_obj_array.find_index { |obj| obj.issuer == cert.issuer })
        raise "missing crl for #{cert.subject} issuer"
      end
      [name,
       ordered_obj_array.unshift(ordered_obj_array.delete_at(idx))
                        .map { |obj| obj.to_pem }
                        .join('')
                        .encode('ascii')]
    }.to_h
  end
end
