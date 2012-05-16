require 'heroku_san/deploy/base'

module HerokuSan
  module Deploy
    class Noop < Base
      def deploy
        # do nothing
      end        
    end
  end
end