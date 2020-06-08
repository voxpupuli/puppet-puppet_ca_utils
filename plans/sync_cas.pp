plan manage_ca_file::sync_cas (
  TargetSpec $remote_ca_hostname,
) {
  $local_ca_hostname = puppetdb_query(@(PQL)).first['certname']
    resources[certname] {
      type = "Class" and
      title = "Puppet_enterprise::Profile::Certificate_authority" }
    | PQL

  # Sync remote and local CA
  $local_ca_resultset = run_task('manage_ca_file::sync_ca', $local_ca_hostname,
    ca_hostname => $remote_ca_hostname
  )

  $all_cas = $local_ca_resultset.first.value['ca']

  # Sync all nodes
  $all_certs = puppetdb_query(@(PQL)).map |$res| { $res['certname'] }
    inventory[certname] {
      facts.aio_agent_version ~ "\\\\d+" }
    | PQL

  # $all_cert_targets = get_targets($all_certs)
  $all_cert_targets = get_targets($all_certs)

  # Write new CAs to agent nodes
  run_task('manage_ca_file::write_file', $all_cert_targets,
    filepath => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
    content => $all_cas,
  )

  # Get remote crl
  $remote_crl_result = run_task('manage_ca_file::remote_crl', $local_ca_hostname,
    ca_hostname => $remote_ca_hostname,
  ).first.value

  # Sync local CRL
  $crl = run_task('manage_ca_file::sync_crl', $local_ca_hostname,
    remote_authority_key_identifiers => $remote_crl_result['keyids'],
    remote_crl_content               => $remote_crl_result['crl']
  ).first.value['crl']

  $all_crl_targets = puppetdb_query(@("PQL")).map |$res| { $res['certname'] }.get_targets
    inventory[certname] { 
      facts.aio_agent_version ~ '\\d+' and 
      facts.trusted.certname != '${local_ca_hostname}' }
    | PQL

  # Write CRLs to agent nodes
  run_task('manage_ca_file::write_file', $all_crl_targets,
    filepath => '/etc/puppetlabs/puppet/ssl/crl.pem',
    content  => $crl,
  )

  # Restart server
  run_task('service', $local_ca_hostname,
    action => 'restart',
    name   => 'pe-puppetserver',
  )
}
