plan change_ca_file::sync_ca_file (
  TargetSpec $ca_hostname,
) {
  # Get remote ca
  $ca_resultset =  run_task('change_ca_file::change_ca_content', localhost, ca_hostname => $ca_hostname)

  $remote_ca = strip($ca_resultset.first().value()['ca'])

  # Get local ca
  $local_ca = file::read('/etc/puppetlabs/puppet/ssl/certs/ca.pem')

  # Check to see if remote ca is already contained in local ca
  $local_ca_include_remote_ca_resultset = run_task('change_ca_file::check_for_existing_ca', localhost, local_ca => $local_ca, remote_ca => $remote_ca)

  $local_ca_include_remote_ca = $local_ca_include_remote_ca_resultset.first().value()['local_ca_include_remote_ca']

  unless $local_ca_include_remote_ca {
    $all_cas = "${remote_ca}\n${local_ca}"

    # file::write('/etc/puppetlabs/puppet/ssl/certs/ca.bk', $local_ca)
    # file::write('/etc/puppetlabs/puppet/ssl/certs/ca.pem', $all_cas)

    # $all_certs_array = puppetdb_query('inventory[certname] { facts.aio_agent_version ~ "\\d+" }')
    $all_certs_array = puppetdb_query('inventory[certname] { facts.fqdn = "new001.fervid.us" }')

    $all_certs = $all_certs_array.map | $cert | {
      $cert['certname']
    }

    $all_cert_targets = get_targets($all_certs)

    apply($all_cert_targets) {
      file { '/etc/puppetlabs/puppet/ssl/certs/ca.pem':
        ensure  => file,
        content => $all_cas,
      }
    }
  }
}
