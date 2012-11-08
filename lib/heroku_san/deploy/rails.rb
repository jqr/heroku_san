require 'heroku_san/deploy/base'

module HerokuSan
  module Deploy
    class Rails < Base
      def deploy
        # TODO: Add announce/logger
        super
        @stage.run('rake db:migrate')
        @stage.restart
      end
    end
  end
end