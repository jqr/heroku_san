module HerokuSan
  module Deploy
    class Base
      def initialize(stage, commit = nil, force = nil)
        @stage = stage
        @commit = commit
        @force = force
      end
      
      def deploy
        @stage.push(@commit, @force)
      end        
    end
  end
end