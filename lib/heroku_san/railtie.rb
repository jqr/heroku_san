require 'heroku_san'
require 'rails'

class HerokuSan
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'heroku_san/tasks.rb'
    end
  end
end
