#!/usr/bin/env ruby

require 'open3'

require_relative '../../ruby_task_helper/files/task_helper.rb'

# Example task that is based on the ruby_task_helper
class CheckForExistingCA < TaskHelper
  def task(name: nil, **kwargs)
    eqs = kwargs[:local_ca] == kwargs[:remote_ca]

    # puts "EQS: #{eqs}"
    local_ca_include_remote_ca = kwargs[:local_ca].include? kwargs[:remote_ca]

    { local_ca_include_remote_ca: local_ca_include_remote_ca }
  end
end

CheckForExistingCA.run if $PROGRAM_NAME == __FILE__