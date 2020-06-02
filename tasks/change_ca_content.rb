#!/usr/bin/env ruby

require 'open3'

require_relative '../../ruby_task_helper/files/task_helper.rb'

# Example task that is based on the ruby_task_helper
class ChangeCAContent < TaskHelper
  def task(name: nil, **kwargs)
    cmd = ['curl', '-k', '-s', "https://#{kwargs[:ca_hostname]}:8140/puppet-ca/v1/certificate/ca"]
    stdout, stderr, status = Open3.capture3(*cmd) # rubocop:disable Lint/UselessAssignment
    raise Puppet::Error, _("stderr: ' %{stderr}') % { stderr: stderr }") if status != 0

    { ca: stdout.strip }
  end
end

ChangeCAContent.run if $PROGRAM_NAME == __FILE__