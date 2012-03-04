require 'railtie' if defined?(Rails) && Rails::VERSION::MAJOR == 3
require 'git'
require 'heroku_san/stage'
require 'heroku_san/project'

module HerokuSan
  class NoApps < StandardError; end
  class MissingApp < StandardError; end
  class Deprecated < StandardError; end
end