require File.join(File.dirname(__FILE__), 'railtie.rb') if defined?(Rails) && Rails::VERSION::MAJOR >= 3
require 'heroku_san/git'
require 'heroku_san/api'
require 'heroku_san/stage'
require 'heroku_san/parser'
require 'heroku_san/project'
require 'heroku_san/configuration'
require 'heroku_san/deploy/rails'
require 'heroku_san/deploy/sinatra'

module HerokuSan
  class << self
    def project
      @project
    end
    def project=(project)
      @project = project
    end
  end
  class NoApps < StandardError; end
  class MissingApp < StandardError; end
  class Deprecated < StandardError; end
end
