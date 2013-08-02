require 'heroku-api'
require 'json'
require_relative 'application'

module HerokuSan
  class Stage
    include HerokuSan::Git
    include HerokuSan::Application

    attr_reader :name, :options, :heroku

    def initialize(stage, options = {})
      @name = stage
      @options = options
      @heroku = options.delete(:api) || HerokuSan::API.new
    end

    def ==(other)
      other.name == name && other.options == options
    end
    
    def app
      @options['app'] or raise MissingApp, "#{name}: is missing the app: configuration value. I don't know what to access on Heroku."
    end
    
    def repo
      @options['repo'] ||= "git@heroku.com:#{app}.git"
    end
    
    def stack
      @options['stack'] ||= heroku.get_stack(app).body.detect{|stack| stack['current']}['name']
    end
    
    def tag
      @options['tag']
    end
    
    def config
      @options['config'] ||= {}
    end

    def addons
      (@options['addons'] ||= []).flatten
    end
    
    def run(command, args = nil)
      heroku.sh app, "run", command, *args
    end
    
    def push(sha = nil, force = false)
      sha ||= git_parsed_tag(tag)
      git_push(sha, repo, force ? %w[--force] : [])
    end
    
    def migrate
      run('rake db:migrate')
      restart
    end
    
    def deploy(commit = nil, force = nil)
      strategy = @options['deploy'].new(self, commit, force)
      strategy.deploy
    end

    def rake(*args)
      raise HerokuSan::Deprecated.new("use Stage#run instead")
    end

    def maintenance(action = nil)
      if block_given?
        heroku.post_app_maintenance(app, '1')
        begin
          yield
        ensure
          heroku.post_app_maintenance(app, '0')
        end
      else
        raise ArgumentError, "Action #{action.inspect} must be one of (:on, :off)", caller if ![:on, :off].include?(action)
        heroku.post_app_maintenance(app, {:on => '1', :off => '0'}[action])
      end
    end
    
    def create
      params = {
          'name' => @options['app'],
          'stack' => @options['stack']
      }
      response = heroku.post_app(params)
      response.body['name']
    end

    def sharing_add(email) # DEPREC?
      raise HerokuSan::Deprecated
    end

    def sharing_remove(email) # DEPREC?
      raise HerokuSan::Deprecated
    end

    def long_config
      heroku.get_config_vars(app).body
    end
    
    def push_config(options = nil)
      params = (options || config)
      heroku.put_config_vars(app, params).body
    end

    def installed_addons
      heroku.get_addons(app).body
    end

    def install_addons
      addons_to_install = addons - installed_addons.map{|a|a['name']}
      addons_to_install.each do |addon|
        heroku.post_addon(app, addon)
      end
      installed_addons
    end

    def restart
      "restarted" if heroku.post_ps_restart(app).body == 'ok'
    end
  
    def logs(tail = false)
      heroku.sh app, 'logs', (tail ? '--tail' : nil)
    end
    
    def revision
      git_named_rev(git_revision(repo))
    end
  end
end
