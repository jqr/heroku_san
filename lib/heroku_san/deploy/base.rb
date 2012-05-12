module HerokuSan
  module Deploy
    class Base
      def initialize(stage, args = {})
        @stage = stage
        @args = args
      end
      
      def deploy
        @stage.push(@args[:commit], @args[:force])
      end        
    end
  end
end