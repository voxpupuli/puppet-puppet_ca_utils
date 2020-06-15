plan manage_ca_file::sync_cas (
  TargetSpec     $targets,
  TargetSpec     $ca_hosts   = $targets,
  Enum[full,api] $crl_bundle = 'full',
) {
  $update_targets = get_targets($targets)
  $ca_targets  = get_targets($ca_hosts)

  $ca_api_data = run_task('manage_ca_file::merge_ca_api_data', 'local://localhost',
    ca_hostnames => $ca_targets.map |$t| { $t.name },
  )[0]

  if ($crl_bundle == 'full') {
    $full_crl_bundle_data = run_task('manage_ca_file::get_full_crl', $ca_targets).map |$r| {
      $r['crl_bundle']
    }.manage_ca_file::merge_crl_bundles()
  }
  else { # $crl_bundle === 'api'
    $full_crl_bundle_data = $ca_api_data['crl_bundle']
  }

  # Note that there is a race condition here around the CRL.
  # See https://tickets.puppetlabs.com/browse/SERVER-2550
  apply($update_targets) {
    File {
      ensure =>  file,
      owner  => 'pe-puppet',
      group  => 'pe-puppet',
    }

    file { '/etc/puppetlabs/puppet/ssl/certs/ca.pem':
      content => $ca_api_data['ca_bundle'],
    }

    file { '/etc/puppetlabs/puppet/ssl/ca/infra_crl.pem':
      content => $ca_api_data['crl_bundle'],
    }

    file { '/etc/puppetlabs/puppet/ssl/ca/ca_crl.pem':
      content => $full_crl_bundle_data,
    }

    # Question: does Puppet Server need reloading?
  }

  # Note: agents and compilers will recieve the updated CA bundle and CRL through normal
  # distribution means

  return('Complete')
}
