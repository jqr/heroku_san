require 'heroku_san/deploy/base'

module HerokuSan
  module Deploy
    class Rails < Base
      def deploy
        # TODO: Add announce/logger
        super
        if Gem::Specification::find_by_name('mongoid')
          @stage.restart
        else
          @stage.rake('db:migrate')
          @stage.restart
        end
      end
    end
  end
end