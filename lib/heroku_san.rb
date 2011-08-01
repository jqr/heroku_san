require 'heroku_san/railtie.rb' if defined?(Rails) && Rails::VERSION::MAJOR == 3
require 'heroku_san/git'

class HerokuSan
  attr_reader :app_settings, :config_file
  class NoApps < StandardError; end
  class Deprecated < StandardError; end

  include Git
    
  def initialize(config_file)
    @apps = []
    @config_file = config_file

    @app_settings = parse_yaml(config_file)
    
    # support heroku_san format
    if @app_settings.has_key? 'apps'
      @app_settings = @app_settings['apps']
      @app_settings.each_pair do |stage, app_name|
        @app_settings[stage] = {'app' => app_name}
      end
    end
    
    # load external config
    if (config_repo = @app_settings.delete('config_repo'))
      require 'tmpdir'
      tmp_config_dir = Dir.mktmpdir
      tmp_config_file = File.join tmp_config_dir, 'config.yml'
      git_clone(config_repo, tmp_config_dir)
      extra_config = parse_yaml(tmp_config_file)
    else
      extra_config = {}
    end
    
    # make sure each app has a 'config' section & merge w/extra
    @app_settings.keys.each do |name|
      @app_settings[name]['config'] ||= {}
      @app_settings[name]['config'].merge!(extra_config[name]) if extra_config[name]
    end    
  end

  def create_config
    template = File.join(File.dirname(__FILE__), 'templates', 'heroku.example.yml')
    if File.exists?(@config_file)
      false
    else
      FileUtils.cp(template, @config_file)
      true
    end
  end
  
  def [](stage)
    @app_settings[stage]
  end
  
  def all
    @app_settings.keys
  end
  
  def <<(*app)
    app.flatten.each do |a|
      @apps << a if all.include?(a)
    end
    self
  end
  
  def apps
    if !@apps.empty?
      @apps
    else
      case all.size
      when 1
        $stdout.puts "Defaulting to #{all.first.inspect} since only one app is defined"
        all
      else
        active_branch = self.git_active_branch
        all.select do |app| 
          app == active_branch and ($stdout.puts("Defaulting to '#{app}' as it matches the current branch") || true)
        end
      end
    end
  end
  
  def each_app
    raise NoApps if apps.empty?
    apps.each do |stage|
      yield(stage, "git@heroku.com:#{self[stage]['app']}.git", self[stage]['config'])
    end
  end
  
  def stack(stage)
    self[stage]['stack'] ||= %x"heroku stack --app #{self[stage]['app']}".split("\n").select { |b| b =~ /^\* / }.first.gsub(/^\* /, '')
  end
  
  def run(stage, command, args = nil)
    if stack(stage) =~ /cedar/
      sh_heroku stage, "run #{command} #{args}"
    else
      sh_heroku stage, "run:#{command} #{args}"
    end
  end
  
  def create(stage)
    sh "heroku apps:create #{self[stage]['app']}"
  end  

  def migrate(stage)
    run(stage, 'rake', 'db:migrate')
    sh_heroku stage, "restart"
  end
  
  def maintenance(stage, action)
    raise ArgumentError, "Action #{action.inspect} must be one of (:on, :off)", caller if ![:on, :off].include?(action)
    
    sh_heroku stage, "maintenance:#{action}"
  end
  
  def sharing_add(stage, email)
    sh_heroku stage, "sharing:add #{email}"
  end
  
  def sharing_remove(stage, email)
    sh_heroku stage, "sharing:remove #{email}"
  end
  
  def long_config(stage)
    sh_heroku stage, 'config --long'
  end
  
  def capture(stage)
    sh_heroku stage, 'bundles:capture'
  end
  
  def restart(stage)
    sh_heroku stage, 'restart'
  end
  
  def logs(stage)
    sh_heroku stage, 'logs'
  end
  
private
  
  def sh_heroku stage, command
    sh "heroku #{command} --app #{self[stage]['app']}"
  end
  
  def parse_yaml(config_file)
    if File.exists?(config_file)
      if defined?(ERB)
        YAML.load(ERB.new(File.read(config_file)).result)
      else
        YAML.load_file(config_file)
      end
    else
      {}
    end
  end
end