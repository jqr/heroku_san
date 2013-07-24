require 'heroku_san/deploy/base'

module HerokuSan
  module Deploy
    class Rails < Base
      def deploy
        # TODO: Add announce/logger
        super
        if @stage.has_pending_migrations
          @stage.run('rake db:migrate')
          @stage.restart
        end
      end
    end
  end
end

