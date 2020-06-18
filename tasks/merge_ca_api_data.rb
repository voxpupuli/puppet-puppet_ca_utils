#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'net/http'
require 'digest'

# Bolt task using helper
class CAMerge < TaskHelper

  CERT_SCAN = /-----BEGIN CERTIFICATE-----(?:.|\n)+?-----END CERTIFICATE-----/
  CRL_SCAN = /-----BEGIN X509 CRL-----(?:.|\n)+?-----END X509 CRL-----/

  def initialize
    @conn = {}
  end

  def task(ca_hostnames:, **kwargs)
    # Open connections to each CA
    ca_hostnames.each { |host| open_connection(host) }

    # Get the cert data from each CA
    ca_bundle = ca_hostnames.map { |host| get_ca_bundle(host).scan(CERT_SCAN) }
                            .flatten
                            .uniq
                            .join("\n")

    # Get the crl data from each CA
    crl_bundle = ca_hostnames.map { |host| get_crl_bundle(host).scan(CRL_SCAN) }
                             .flatten
                             .map { |crl| OpenSSL::X509::CRL.new(crl) }
                             .group_by { |crl| crl.issuer.hash }
                             .map { |_,crls| crls.max_by { |crl| crl.last_update } }
                             .map { |crl| crl.to_pem }
                             .join('')

    # Get the peer cert from each CA
    peer_certs = ca_hostnames.map { |host| [hostname, get_peer_cert(hostname)] }.to_h

    ca_hostnames.each { |host| close_connection(host) }

    # Return the merged data
    { ca_bundle:  ca_bundle,
      crl_bundle: crl_bundle,
      peer_certs: peer_certs }
  rescue => e
    TaskHelper::Error.new(e.message,
                          'merge-ca-api-data/error',
                          { 'backtrace' => e.backtrace })
  end

  def get_ca_bundle(host)
    response = connection(host).get('/puppet-ca/v1/certificate/ca')
    response.body
  end

  def get_crl_bundle(host)
    response = connection(host).get('/puppet-ca/v1/certificate_revocation_list/ca')
    response.body
  end

  def get_peer_cert(host)
    connection(host).peer_cert.to_pem
  end

  def connection(host)
    @conn[host] ||= open_connection(host)
  end

  def open_connection(host)
    uri = URI("https://#{host}:8140")
    @conn[uri.host] = Net::HTTP.new(uri.host, uri.port)
    @conn[uri.host].use_ssl = true
    @conn[uri.host].verify_mode = OpenSSL::SSL::VERIFY_NONE
    @conn[uri.host].start
  end

  def close_connection(host)
    @conn[host].finish
    @conn.delete(host)
    nil
  end
end

CAMerge.run if $PROGRAM_NAME == __FILE__
