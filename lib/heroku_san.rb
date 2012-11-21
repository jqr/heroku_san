require File.join(File.dirname(__FILE__), 'railtie.rb') if defined?(Rails) && Rails::VERSION::MAJOR >= 3
require 'git'
require 'heroku_san/stage'
require 'heroku_san/project'
require 'heroku_san/deploy/rails'
require 'heroku_san/deploy/sinatra'

module HerokuSan
  mattr_accessor :project
  class NoApps < StandardError; end
  class MissingApp < StandardError; end
  class Deprecated < StandardError; end
end
