require 'heroku-api'
require 'json'

MOCK = false unless defined?(MOCK)

module HerokuSan
  class Stage
    attr_reader :name
    include Git
    
    def initialize(stage, options = {})
      default_options = {
        'deploy' => HerokuSan::Deploy::Rails
      }
      @name = stage
      @options = default_options.merge(options)
    end
    
    def heroku
      @heroku ||= Heroku::API.new(:api_key => auth_token, :mock => MOCK)
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
      sh_heroku "run", command, *args
    end
    
    def push(sha = nil, force = false)
      (sha = sha + "^{commit}") if sha
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
      sh_heroku 'logs', (tail ? '--tail' : nil)
    end
    
    def revision
      git_named_rev(git_revision(repo))
    end
    
  private

    def auth_token
      @auth_token ||= (ENV['HEROKU_API_KEY'] || `heroku auth:token`.chomp unless MOCK)
    end

    def sh_heroku(*command)
      preflight_check_for_cli
      cmd = (command + ['--app', app]).compact
      show_command = cmd.join(' ')
      $stderr.puts show_command if @debug
      ok = system "heroku", *cmd
      status = $?
      ok or fail "Command failed with status (#{status.exitstatus}): [heroku #{show_command}]"
    end

    def preflight_check_for_cli
      raise "The Heroku Toolbelt is required for this action. http://toolbelt.heroku.com" if system('heroku version') == nil
    end
  end
end
