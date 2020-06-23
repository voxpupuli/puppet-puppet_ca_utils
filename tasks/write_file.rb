#!/opt/puppetlabs/puppet/bin/ruby
require 'fileutils'

require_relative '../../ruby_task_helper/files/task_helper.rb'

# Example task that is based on the ruby_task_helper
class WriteFile < TaskHelper
  def task(name: nil, **kwargs)
    result = File.write(kwargs[:filepath], kwargs[:content])

    FileUtils.chown kwargs[:owner], nil, kwargs[:filepath] if kwargs[:owner]
    FileUtils.chown nil, kwargs[:group], kwargs[:filepath] if kwargs[:group]

    { result: result }
  end
end

WriteFile.run if $PROGRAM_NAME == __FILE__