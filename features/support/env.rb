$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')

# ensure test-config submodule has been cloned
unless File.readable? File.join(File.dirname(__FILE__), '..', 'data', 'test-config', 'config.yml')
  `git submodule init && git submodule update`
end
