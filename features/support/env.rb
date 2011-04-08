$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')

require 'aruba/cucumber'

Before do
  @aruba_timeout_seconds = 60
end
