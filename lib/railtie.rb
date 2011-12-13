require 'heroku_san'
require 'rails'

module HerokuSan
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks.rb'
    end
  end
end
