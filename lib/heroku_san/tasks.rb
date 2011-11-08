HEROKU_CONFIG_FILE = Rails.root.join('config', 'heroku.yml')

@app_settings =
  if File.exists?(HEROKU_CONFIG_FILE)
    if defined?(ERB)
      YAML.load(ERB.new(File.read(HEROKU_CONFIG_FILE)).result)
    else
      YAML.load_file(HEROKU_CONFIG_FILE)
    end
  else
    {}
  end

if @app_settings.has_key? 'apps'
  @app_settings = @app_settings['apps']
  @app_settings.each_pair do |shorthand, app_name|
    @app_settings[shorthand] = {'app' => app_name}
  end
end

@config_repo = @app_settings.delete('config_repo')
def retrieve_configuration
  unless @config_repo.nil?
    #load external config
    require 'tmpdir'
    tmp_config_dir = Dir.mktmpdir
    tmp_config_file = File.join tmp_config_dir, 'config.yml'
    sh "git clone #{@config_repo} #{tmp_config_dir}"
    @extra_config =
      if File.exists?(tmp_config_file)
        if defined?(ERB)
          YAML.load(ERB.new(File.read(tmp_config_file)).result)
        else
          YAML.load_file(tmp_config_file)
        end
      else
        {}
      end
  end
end

(@app_settings.keys || []).each do |name|
  desc "Select #{name} Heroku app for later commands"
  task name do
    @heroku_apps ||= []
    @heroku_apps << name
  end
end

desc 'Select all Heroku apps for later command'
task :all do
  @heroku_apps = @app_settings.keys
end

namespace :heroku do
  desc "Creates the Heroku app"
  task :create do
    each_heroku_app do |name, app, repo|
      sh "heroku create #{app} #{("--stack " + stack(app)) if stack(app)}"
    end
  end

  desc "Generate the Heroku gems manifest from gem dependencies"
  task :gems => 'gems:base' do
    RAILS_ENV='production'
    Rake::Task[:environment].invoke
    gems = Rails.configuration.gems.reject { |g| g.frozen? && !g.framework_gem? }
    list = gems.collect do |g|
      command, *options = g.send(:install_command)
      options.join(" ")
    end

    list.unshift(%Q{rails --version "= #{Rails.version}"})

    File.open(Rails.root.join('.gems'), 'w') do |f|
      f.write(list.join("\n"))
    end
  end

  desc 'Add git remotes for all apps in this project'
  task :remotes do
    each_heroku_app do |name, app, repo|
      system("git remote add #{name} #{repo}")
    end
  end

  desc 'Adds a collaborator'
  task :share do
    print "Email address of collaborator to add: "
    $stdout.flush
    email = $stdin.gets
    each_heroku_app do |name, app, repo|
      sh "heroku sharing:add --app #{app} #{email}"
    end
  end

  desc 'Removes a collaborator'
  task :unshare do
    print "Email address of collaborator to remove: "
    $stdout.flush
    email = $stdin.gets
    each_heroku_app do |name, app, repo|
      sh "heroku sharing:remove --app #{app} #{email}"
    end
  end

  desc 'Lists configured apps'
  task :apps => :all do
    each_heroku_app do |name, app, repo|
      puts  "#{name} is shorthand for the Heroku app #{app} located at:"
      puts  "  #{repo}"
      print "  @ "
      rev = `git ls-remote -h #{repo}`.split(' ').first
      if rev.blank?
        puts 'not deployed'
      else
        puts `git name-rev #{rev}`
      end
      puts
    end
  end

  namespace :apps do
    desc 'Lists configured apps without hitting Heroku'
    task :local => :all do
      each_heroku_app do |name, app, repo|
        puts "#{name} is shorthand for the Heroku app #{app} located at:"
        puts "  #{repo}"
        puts
      end
    end
  end

  desc 'Add proper RACK_ENV to each application'
  task :rack_env => :all do
    each_heroku_app do |name, app, repo|
      command = "heroku config --app #{app}"
      puts command
      config = Hash[`#{command}`.scan(/^(.+?)\s*=>\s*(.+)$/)]
      if config['RACK_ENV'] != name
        sh "heroku config:add --app #{app} RACK_ENV=#{name}"
      end
    end
  end

  desc 'Creates an example configuration file'
  task :create_config do
    example = File.join(File.dirname(__FILE__), '..', 'templates', 'heroku.example.yml')
    if File.exists?(HEROKU_CONFIG_FILE)
      puts "config/heroku.yml already exists"
    else
      puts "Copied example config to config/heroku.yml"
      FileUtils.cp(example, HEROKU_CONFIG_FILE)
      if ENV['EDITOR'].present?
        sh("#{ENV['EDITOR']} #{HEROKU_CONFIG_FILE}")
      else
        puts "Please edit config/heroku.yml with your application's settings."
      end
    end
  end

  desc 'Add config:vars to each application'
  task :config do
    retrieve_configuration
    each_heroku_app do |name, app, repo, config|
      command = "heroku config:add --app #{app}"
      config.each do |var, value|
        command += " #{var}=#{value}"
      end
      sh(command)
    end
  end

  namespace :config do
    desc "Lists config variables as set on Heroku"
    task :list do
      each_heroku_app do |name, app|
        puts "#{name}:"
        sh "heroku config --app #{app} --long"
      end
    end

    namespace :list do
      desc "Lists local config variables without setting them"
      task :local do
        retrieve_configuration
        each_heroku_app do |name, app, repo, config|
          (config).each do |var, value|
            puts "#{name} #{var}: '#{value}'"
          end
        end
      end
    end
  end
  
  desc 'Runs a rake task remotely'
  task :rake, :task do |t, args|
    each_heroku_app do |name, app, repo|
      sh "heroku #{run_or_rake(app)} #{args[:task]}"
    end
  end

  desc "Pushes the given commit (default: HEAD)"
  task :push, :commit do |t, args|
    each_heroku_app do |name, app, repo|
      push(args[:commit], repo)
    end
  end

  namespace :push do
    desc "Force-pushes the given commit (default: HEAD)"
    task :force, :commit do |t, args|
      @git_push_arguments ||= []
      @git_push_arguments << '--force'
      Rake::Task[:'heroku:push'].execute(args)
    end
  end

  desc "Enable maintenance mode"
  task :maintenance do
    each_heroku_app do |name, app, repo|
      maintenance(app, 'on')
    end
  end

  desc "Disable maintenance mode"
  task :maintenance_off do
    each_heroku_app do |name, app, repo|
      maintenance(app, 'off')
    end
  end
end

desc "Pushes the given commit, migrates and restarts (default: HEAD)"
task :deploy, [:commit] => [:before_deploy] do |t, args|
  each_heroku_app do |name, app, repo|
    push(args[:commit], repo)
    migrate(app)
  end
  Rake::Task[:after_deploy].execute
end

namespace :deploy do
  desc "Force-pushes the given commit, migrates and restarts (default: HEAD)"
  task :force, :commit do |t, args|
    @git_push_arguments ||= []
    @git_push_arguments << '--force'
    Rake::Task[:deploy].invoke(args[:commit])
  end
end

# Deprecated.
task :force_deploy do
  Rake::Task[:'deploy:force'].invoke
end

desc "Callback before deploys"
task :before_deploy do
end

desc "Callback after deploys"
task :after_deploy do
end

desc "Captures a bundle on Heroku"
task :capture do
  each_heroku_app do |name, app, repo|
    sh "heroku bundles:capture --app #{app}"
  end
end

desc "Opens a remote console"
task :console do
  each_heroku_app do |name, app, repo|
    if stack_is_cedar?(app)
      sh "heroku run --app #{app} console"
    else
      sh "heroku console --app #{app}"
    end
  end
end

desc "Restarts remote servers"
task :restart do
  each_heroku_app do |name, app, repo|
    sh "heroku restart --app #{app}"
  end
end

desc "Migrates and restarts remote servers"
task :migrate do
  each_heroku_app do |name, app, repo|
    migrate(app)
  end
end

desc "Shows the Heroku logs"
task :logs do
  each_heroku_app do |name, app, repo|
    sh "heroku logs --app #{app}"
  end
end

namespace :db do
  desc 'Pull the Heroku database'
  task :pull do
    dbconfig = YAML.load(ERB.new(File.read(Rails.root.join('config/database.yml'))).result)[Rails.env]
    return if dbconfig['adapter'] != 'postgresql'

    each_heroku_app do |name, app, repo|
      oldest = `heroku pgbackups --app #{app}`.split("\n")[2].split(" ").first
      sh "heroku pgbackups:destroy #{oldest} --app #{app}"

      sh "heroku pgbackups:capture --app #{app}"
      dump = `heroku pgbackups --app #{app}`.split("\n").last.split(" ").first
      sh "mkdir -p #{Rails.root}/db/dumps"
      file = "#{Rails.root}/db/dumps/#{dump}"
      url = `heroku pgbackups:url --app #{app} #{dump}`.chomp
      sh "wget", url, "-O", file

      sh "rake db:setup"
      sh "pg_restore --verbose --clean --no-acl --no-owner -h #{dbconfig['host']} -p #{dbconfig['port']} -U #{dbconfig['username']} -d #{dbconfig['database']} #{file}"
      sh "rake jobs:clear"
    end
  end

  desc 'Push local database to Heroku database'
  task :push do
    dbconfig = YAML.load(ERB.new(File.read(Rails.root.join('config/database.yml'))).result)[Rails.env]
    return if dbconfig['adapter'] != 'postgresql'

    each_heroku_app do |name, app, repo|
      sh "heroku db:push postgres://#{dbconfig['username']}:#{dbconfig['password']}@#{dbconfig['host']}/#{dbconfig['database']} --app #{app}"
    end
  end
end

def each_heroku_app
  if @heroku_apps.blank? 
    if @app_settings.keys.size == 1
      app = @app_settings.keys.first
      puts "Defaulting to #{app} app since only one app is defined"
      @heroku_apps = [app]
    else
      @app_settings.keys.each do |key|
        active_branch = %x{git branch}.split("\n").select { |b| b =~ /^\*/ }.first.split(" ").last.strip
        if key == active_branch
          puts "Defaulting to #{key} as it matches the current branch"
          @heroku_apps = [key]
        end
      end
    end
  end

  if @heroku_apps.present?
    @heroku_apps.each do |name|
      app = @app_settings[name]['app']
      config = @app_settings[name]['config'] || {}
      config.merge!(@extra_config[name]) if (@extra_config && @extra_config[name])
      if @app_settings[name].has_key? 'repo'
        repo = @app_settings[name]['repo']
      else
        repo = "git@heroku.com:#{app}.git"
      end
      yield(name, app, repo, config)
    end
    puts
  else
    puts "You must first specify at least one Heroku app:
      rake <app> [<app>] <command>
      rake production restart
      rake demo staging deploy"

    puts "\nYou can use also command all Heroku apps for this project:
      rake all heroku:share"

    exit(1)
  end
end

def push(commit, repo)
  commit ||= "HEAD"
  @git_push_arguments ||= []
  begin
    sh "git update-ref refs/heroku_san/deploy #{commit}"
    sh "git push #{repo} #{@git_push_arguments.join(' ')} refs/heroku_san/deploy:refs/heads/master"
  ensure
    sh "git update-ref -d refs/heroku_san/deploy"
  end
end

def migrate(app)
  sh "heroku #{run_or_rake(app)} db:migrate"
  sh "heroku restart --app #{app}"
end

def maintenance(app, action)
  sh "heroku maintenance:#{action} --app #{app}"
end

# `heroku rake foo` has been superseded by `heroku run rake foo` on cedar
def run_or_rake(app)
  if stack_is_cedar?(app)
    "run --app #{app} rake"
  else
    "rake --app #{app}"
  end
end

def stack_is_cedar?(app)
  stack(app) =~ /^cedar/
end

def stack(app)
  @app_settings.values.detect { |s| s['app'] == app }.tap do |settings|
    @stack = (settings['stack'] || (/^\* (.*)/.match `heroku stack --app #{app}`)[1] rescue nil)
  end
  @stack
end
