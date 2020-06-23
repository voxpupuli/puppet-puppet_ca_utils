# frozen_string_literal: true

require 'net/http'
require 'openssl'

Puppet::Functions.create_function(:'mutual_ca_trust::merge_crl_bundles') do
  dispatch :merge_crl_bundles do
    repeated_param 'Variant[String, Array[String]]', :bundles
  end

  def merge_crl_bundles(*bundles)
    crl_scan = /-----BEGIN X509 CRL-----(?:.|\n)+?-----END X509 CRL-----/

    bundles.flatten
           .map { |pem| pem.scan(crl_scan) }
           .flatten
           .map { |crl| OpenSSL::X509::CRL.new(crl) }
           .group_by { |crl| crl.issuer.hash }
           .map { |_,crls| crls.max_by { |crl| crl.last_update } }
           .map { |crl| crl.to_pem }
           .join('')
           .encode('ascii')
  end
end
