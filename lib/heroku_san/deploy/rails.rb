require 'heroku_san/deploy/base'

module HerokuSan
  module Deploy
    class Rails < HerokuSan::Deploy::Base
      def deploy
        $stderr.puts super
        $stderr.puts @stage.rake('db:migrate')
        $stderr.puts @stage.restart
      end
    end
  end
end