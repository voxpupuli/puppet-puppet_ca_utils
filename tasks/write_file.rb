#!/opt/puppetlabs/puppet/bin/ruby

require 'open3'

require_relative '../../ruby_task_helper/files/task_helper.rb'

# Example task that is based on the ruby_task_helper
class WriteFile < TaskHelper
  def task(name: nil, **kwargs)
    result = File.write(kwargs[:filepath], kwargs[:content])

    { result: result }
  end
end

WriteFile.run if $PROGRAM_NAME == __FILE__
