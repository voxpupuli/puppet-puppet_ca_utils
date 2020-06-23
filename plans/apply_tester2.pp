plan manage_ca_file::apply_tester2(
  Enum[white,black] $enum_tester = 'white',
) {
  $update_targets = get_targets('puppet002.azcender.com')

  if($enum_tester == 'white') {
    $potato = '1'
  }
  else {
    $potato = '2'
  }

  # Note that there is a race condition here around the CRL.
  # See https://tickets.puppetlabs.com/browse/SERVER-2550
  apply($update_targets) {
    $restart_puppetserver = true

    File {
      ensure => file,
      owner  => 'pe-puppet',
      group  => 'pe-puppet',
      notify => $restart_puppetserver ? {
        true  => Service['pe-puppetserver'],
        false => undef,
      },
    }

    service { 'pe-puppetserver': }

    # notify { 'hello': }
  }

  # Note: agents and compilers will recieve the updated CA bundle and CRL through normal
  # distribution means

  return('Complete')
}
