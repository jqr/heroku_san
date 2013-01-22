$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')

require 'aruba/cucumber'

# ensure test-config submodule has been cloned
unless File.readable? File.join(File.dirname(__FILE__), '..', 'data', 'test-config', 'config.yml')
  `git submodule init && git submodule update`
end

Before do
  @aruba_timeout_seconds = 15
end
  
Before('@slow_process') do
  @aruba_timeout_seconds = 5 * 60
  # @aruba_io_wait_seconds = 15
end
