plan manage_ca_file::sync_cas (
  TargetSpec $remote_ca_hostname,
) {
  $local_ca_hostname_array = puppetdb_query('resources[certname] { type = "Class" and title = "Puppet_enterprise::Profile::Certificate_authority" }')
  $local_ca_hostname = $local_ca_hostname_array[0]['certname']

  # Get local ca
  $local_ca_resultset = run_task('manage_ca_file::sync_ca', $local_ca_hostname, ca_hostname => $remote_ca_hostname)

  $all_cas = $local_ca_resultset.first().value()['ca']

  # Sync all nodes
  $all_certs_array = puppetdb_query('inventory[certname] { facts.aio_agent_version ~ "\\\\d+" }')

  $all_certs = $all_certs_array.map | $cert | {
    $cert['certname']
  }

  # $all_cert_targets = get_targets($all_certs)
  $all_cert_targets = get_targets($all_certs)

  # Check to see if remote ca is already contained in local ca
  $write_new_ca_resultset = run_task('manage_ca_file::write_file', $all_cert_targets, filepath => '/etc/puppetlabs/puppet/ssl/certs/ca.pem', content => $all_cas)

  # Get remote ca
  $crl_resultset =  run_task('manage_ca_file::remote_crl', $local_ca_hostname, ca_hostname => $remote_ca_hostname)

  $remote_crl_result = $crl_resultset.first().value()

  # Get local ca
  $local_crl_resultset = run_task(
                                  'manage_ca_file::sync_crl',
                                  $local_ca_hostname,
                                  remote_authority_key_identifiers => $remote_crl_result['keyids'],
                                  remote_crl_content => $remote_crl_result['crl']
                                )

  $crl = $local_crl_resultset.first().value()['crl']

  $all_crls_nodes_array = puppetdb_query("inventory[certname] { facts.aio_agent_version ~ '\\d+' and facts.trusted.certname != '${local_ca_hostname}' }")

  $all_crl_nodes = $all_crls_nodes_array.map | $crl_node | {
    $crl_node['certname']
  }

  # $all_cert_targets = get_targets($all_certs)
  $all_crl_targets = get_targets($all_crl_nodes)

  # Check to see if remote ca is already contained in local ca
  $write_new_crl_resultset = run_task('manage_ca_file::write_file', $all_crl_targets, filepath => '/etc/puppetlabs/puppet/ssl/crl.pem', content => $crl)
}
