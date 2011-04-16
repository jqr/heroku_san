$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')

require 'aruba/cucumber'

Before do
  @aruba_timeout_seconds = 60
end

# ensure test-config submodule has been cloned
unless File.readable? File.join(File.dirname(__FILE__), '..', 'data', 'test-config', 'config.yml')
  `git submodule init && git submodule update`
end
