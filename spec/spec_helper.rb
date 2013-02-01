require 'bundler'
Bundler.setup

SPEC_ROOT = File.dirname(__FILE__)

MOCK = ENV['MOCK'] != 'false'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(SPEC_ROOT, "support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec
end

def fixture(filename)
  File.join(SPEC_ROOT, "fixtures", filename)
end

require File.join(SPEC_ROOT, '/../lib/heroku_san')