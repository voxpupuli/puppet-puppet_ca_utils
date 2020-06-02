plan manage_ca_file::sync_ca_file (
  TargetSpec $remote_ca_hostname,
) {
  $local_ca_hostname_array = puppetdb_query('resources[certname] { type = "Class" and title = "Puppet_enterprise::Profile::Certificate_authority" }')
  $local_ca_hostname = $local_ca_hostname_array[0]['certname']

  # Get remote ca
  $ca_resultset =  run_task('manage_ca_file::remote_ca_content', $local_ca_hostname, ca_hostname => $remote_ca_hostname)

  $remote_ca = strip($ca_resultset.first().value()['ca'])

  # Get local ca
  $local_ca_resultset = run_task('manage_ca_file::remote_ca_content', $local_ca_hostname, ca_hostname => $local_ca_hostname)

  $local_ca = $local_ca_resultset.first().value()['ca']

  # Check to see if remote ca is already contained in local ca
  $local_ca_include_remote_ca_resultset = run_task('manage_ca_file::check_for_existing_ca', $local_ca_hostname, local_ca => $local_ca, remote_ca => $remote_ca_hostname)

  $local_ca_include_remote_ca = $local_ca_include_remote_ca_resultset.first().value()['local_ca_include_remote_ca']

  # Sync all nodes
  unless $local_ca_include_remote_ca {
    $all_cas = "${remote_ca}\n${local_ca}"

    $all_certs_array = puppetdb_query('inventory[certname] { facts.aio_agent_version ~ "\\\\d+" }')

    $all_certs = $all_certs_array.map | $cert | {
      $cert['certname']
    }

    # $all_cert_targets = get_targets($all_certs)
    $all_cert_targets = get_targets($all_certs)

    # Check to see if remote ca is already contained in local ca
    $write_new_ca_resultset = run_task('manage_ca_file::write_file', $all_cert_targets[1], filepath => '/etc/puppetlabs/puppet/ssl/certs/ca.pem', content => $all_cas)
  }
}
