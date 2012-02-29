module HerokuSan
  class Stage
    attr_reader :name
    include Git
    
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
    
    def deploy(sha = nil, force = false)
      sha ||= git_parsed_tag(self.tag)
      git_push(sha, self.repo, force ? %w[--force] : [])
    end
    
    def migrate
      run 'rake', 'db:migrate'
      sh_heroku "restart"
    end

    def maintenance(action = nil)
      if block_given?
        sh_heroku "maintenance:on"
        begin
          yield
        ensure
          sh_heroku "maintenance:off"
        end
      else
        raise ArgumentError, "Action #{action.inspect} must be one of (:on, :off)", caller if ![:on, :off].include?(action)
        sh_heroku "maintenance:#{action}"
      end
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
    
    def push_config(options = {})
      vars = (options == {} ? self.config : options).map {|var,value| "#{var}=#{Shellwords.escape(value)}"}.join(' ')
      sh_heroku "config:add #{vars}"
    end

    def restart
      sh_heroku 'restart'
    end
  
    def logs
      sh_heroku 'logs'
    end
    
  private
  
    def sh_heroku(command)
      sh "heroku #{command} --app #{app}"
    end
  end
end