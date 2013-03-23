require 'bundler'
Bundler.setup

SPEC_ROOT = File.dirname(__FILE__)

MOCK = ENV['MOCK'] != 'false'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(SPEC_ROOT, "support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rspec
end

require File.join(SPEC_ROOT, '/../lib/heroku_san')