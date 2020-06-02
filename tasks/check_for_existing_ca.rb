#!/opt/puppetlabs/puppet/bin/ruby

require 'open3'

require_relative '../../ruby_task_helper/files/task_helper.rb'

# Example task that is based on the ruby_task_helper
class CheckForExistingCA < TaskHelper
  def task(name: nil, **kwargs)
    local_ca_include_remote_ca = kwargs[:local_ca].include? kwargs[:remote_ca]

    { local_ca_include_remote_ca: local_ca_include_remote_ca }
  end
end

CheckForExistingCA.run if $PROGRAM_NAME == __FILE__
