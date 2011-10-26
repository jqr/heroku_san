module HerokuSan
  class Stage
    attr_reader :name
    
    def initialize(stage, options = {})
      @name = stage
      @options = options
    end
    
    def app
      @options['app']
    end
    
    def repo
      @options['repo'] ||= "git@heroku.com:#{app}.git"
    end
    
    def stack
      @options['stack'] ||= %x"heroku stack --app #{app}".split("\n").select { |b| b =~ /^\* / }.first.gsub(/^\* /, '')
    end
    
    def tag
      @options['tag']
    end
    
    def config
      @options['config'] ||= {}
    end
    
    def run(command, args = nil)
      if stack =~ /cedar/
        sh_heroku "run #{command} #{args}"
      else
        sh_heroku "run:#{command} #{args}"
      end
    end
    
    def migrate
      run('rake', 'db:migrate')
      sh_heroku "restart"
    end

    def maintenance(action)
      raise ArgumentError, "Action #{action.inspect} must be one of (:on, :off)", caller if ![:on, :off].include?(action)
      sh_heroku "maintenance:#{action}"
    end
    
    def create
      sh "heroku apps:create #{app}" + (@options['stack'] ? " --stack #{@options['stack']}" : '')
    end

    def sharing_add(email)
      sh_heroku "sharing:add #{email.chomp}"
    end
  
    def sharing_remove(email)
      sh_heroku "sharing:remove #{email.chomp}"
    end
  
    def long_config
      sh_heroku 'config --long'
    end

    def restart
      sh_heroku 'restart'
    end
  
    def logs
      sh_heroku 'logs'
    end
    
  private
  
    def sh_heroku command
      sh "heroku #{command} --app #{app}"
    end
  end
end