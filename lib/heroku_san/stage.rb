module HerokuSan
  class Stage
    attr_reader :name
    include Git
    
    def initialize(stage, options = {})
      @name = stage
      @options = options
    end
    
    def heroku
      Heroku::Auth.client
    end

    def app
      @options['app'] or raise MissingApp, "#{name}: is missing the app: configuration value. I don't know what to access on Heroku."
    end
    
    def repo
      @options['repo'] ||= "git@heroku.com:#{app}.git"
    end
    
    def stack
      @options['stack'] ||= heroku.list_stacks(app).detect{|stack| stack['current']}['name']
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
      sha ||= git_parsed_tag(tag)
      git_push(sha, repo, force ? %w[--force] : [])
    end
    
    def migrate
      rake('db:migrate') + restart
    end
    
    def rake(*args)
      heroku.rake app, args.join(' ')
    end

    def maintenance(action = nil)
      if block_given?
        heroku.maintenance(app, :on)
        begin
          yield
        ensure
          heroku.maintenance(app, :off)
        end
      else
        raise ArgumentError, "Action #{action.inspect} must be one of (:on, :off)", caller if ![:on, :off].include?(action)
        heroku.maintenance(app, action)
      end
    end
    
    def create # DEPREC?
      if @options['stack']
        heroku.create(app, {:stack => @options['stack']})
      else
        heroku.create(app)
      end
    end

    def sharing_add(email) # DEPREC?
      sh_heroku "sharing:add #{email.chomp}"
    end
  
    def sharing_remove(email) # DEPREC?
      sh_heroku "sharing:remove #{email.chomp}"
    end
  
    def long_config
      heroku.config_vars(app)
    end
    
    def push_config(options = nil)
      heroku.add_config_vars(app, options || config)
    end

    def restart
      heroku.ps_restart(app)
    end
  
    def logs(tail = false)
      sh_heroku 'logs' + (tail ? ' --tail' : '')
    end
    
    def revision
      git_named_rev(git_revision(repo))
    end
    
  private
  
    def sh_heroku(command)
      sh "heroku #{command} --app #{app}"
    end
  end
end