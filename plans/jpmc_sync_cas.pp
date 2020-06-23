plan manage_ca_file::jpmc_sync_cas (
  TargetSpec $ca_host,
) {
  $local_ca_query = 'resources[certname] { type = "Class" and title = "Puppet_enterprise::Profile::Certificate_authority" }'
  $local_ca_hostname_array = puppetdb_query($local_ca_query)
  $local_ca_hostname = $local_ca_hostname_array[0]['certname']

  $target = get_target($local_ca_hostname)

  $all_cas = unique(flatten($target, $ca_host))

  run_plan('manage_ca_file::sync_cas', targets => $target, ca_hosts => $all_cas, crl_bundle => 'api', restart_puppetserver => true) #, task_run_host => $target)

  $all_crl_nodes_query = "inventory[certname] { facts.aio_agent_version ~ '\\d+' and facts.trusted.certname != '${target}' }"
  $all_crls_nodes_array = puppetdb_query($all_crl_nodes_query)

  $all_crl_nodes = $all_crls_nodes_array.map | $crl_node | {
    $crl_node['certname']
  }

  $all_crl_targets = get_targets($all_crl_nodes)

  # Write certs to agent nodes
  run_task('manage_ca_file::setup_agent', $all_crl_targets, server => $target.name)

  return('Complete')
}
