plan manage_ca_file::sync_cas (
  TargetSpec     $targets,
  TargetSpec     $ca_hosts             = $targets,
  Enum[full,api] $crl_bundle           = 'full',
  Boolean        $restart_puppetserver = false,
) {
  $update_targets = get_targets($targets)
  $ca_targets  = get_targets($ca_hosts)

  $api_ca_data = run_task('manage_ca_file::api_ca_data', $update_targets[0],
    ca_hostnames => $ca_targets.map |$t| { $t.name },
  )[0]

  if ($crl_bundle == 'full') {
    $full_crl_bundle = run_task('manage_ca_file::get_ca_crl', $ca_targets).map |$r| {
      $r['ca_crl']
    }.manage_ca_file::merge_crl_bundles()
  }
  else { # $crl_bundle == 'api'
    $full_crl_bundle = $api_ca_data['crl_bundle']
  }

  $ordered_pem_bundles = {
    'ca_crt'    => manage_ca_file::ordered_ca_bundles($api_ca_data['peer_certs'], $api_ca_data['ca_bundle']),
    'ca_crl'    => manage_ca_file::ordered_crl_bundles($api_ca_data['peer_certs'], $full_crl_bundle),
    'infra_crl' => manage_ca_file::ordered_crl_bundles($api_ca_data['peer_certs'], $api_ca_data['crl_bundle']),
  }

  # We will use the 'name' var in the apply block below
  $update_targets.each |$target| {
    # $target.set_var('local_name', $target.name)
    run_task('manage_ca_file::write_file', $target, filepath => '/etc/puppetlabs/puppet/ssl/certs/ca.pem', content => $ordered_pem_bundles['ca_crt'][$target.name], owner => pe-puppet, group => pe-puppet)
    run_task('manage_ca_file::write_file', $target, filepath => '/etc/puppetlabs/puppet/ssl/ca/ca_crl.pem', content => $ordered_pem_bundles['ca_crl'][$target.name], owner => pe-puppet, group => pe-puppet)
    run_task('manage_ca_file::write_file', $target, filepath => '/etc/puppetlabs/puppet/ssl/ca/infra_crl.pem', content => $ordered_pem_bundles['infra_crl'][$target.name], owner => pe-puppet, group => pe-puppet)

    run_task('service', $target, action => 'restart', name => 'pe-puppetserver')
  }

  # Note: agents and compilers will recieve the updated CA bundle and CRL through normal
  # distribution means

  return('Complete')
}
