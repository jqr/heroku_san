require 'railtie' if defined?(Rails) && Rails::VERSION::MAJOR == 3
require 'git'
require 'heroku_san/stage'
require 'heroku_san/project'
require 'heroku_san/addons'

module HerokuSan
  class NoApps < StandardError; end
  class Deprecated < StandardError; end
end
