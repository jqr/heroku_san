require 'heroku_san/deploy/base'

module HerokuSan
  module Deploy
    class Sinatra < HerokuSan::Deploy::Base
      def deploy
        $stderr.puts super
      end
    end
  end
end