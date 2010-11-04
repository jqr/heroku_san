HEROKU_CONFIG_FILE = Rails.root.join('config', 'heroku.yml')

HEROKU_SETTINGS =
  if File.exists?(HEROKU_CONFIG_FILE)
    YAML.load_file(HEROKU_CONFIG_FILE) 
  else
    {} 
  end

(HEROKU_SETTINGS['apps'] || []).each do |name, app|
  desc "Select #{name} Heroku app for later commands"
  task name do
    @heroku_apps ||= [] 
    @heroku_apps << name
  end
end

desc 'Select all Heroku apps for later command'
task :all do
  @heroku_apps = HEROKU_SETTINGS['apps'].keys
end

namespace :heroku do
  desc "Creates the Heroku app"
  task :create do
    each_heroku_app do |name, app, repo|
      system_with_echo "heroku create #{app}"
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
      system_with_echo "heroku sharing:add --app #{app} #{email}"
    end
  end

  desc 'Adds a collaborator'
  task :unshare do
    print "Email address of collaborator to remove: "
    $stdout.flush
    email = $stdin.gets
    each_heroku_app do |name, app, repo|
      system_with_echo "heroku sharing:remove --app #{app} #{email}"
    end
  end

  desc 'Lists configured apps'
  task :apps => :all do
    each_heroku_app do |name, app, repo|
      puts "#{name} is shorthand for the Heroku app #{app} located at:"
      puts "  #{repo}"
      puts
    end
  end
  
  desc 'Add proper RACK_ENV to each application'
  task :rack_env => :all do
    each_heroku_app do |name, app, repo|
      command = "heroku config --app #{app}"
      puts command
      config = Hash[`#{command}`.scan(/^(.+?)\s*=>\s*(.+)$/)]
      if config['RACK_ENV'] != name
        system_with_echo "heroku config:add --app #{app} RACK_ENV=#{name}"
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
      system_with_echo("#{ENV['EDITOR']} #{HEROKU_CONFIG_FILE}")
    end
  end

  desc 'Runs a rake task remotely'
  task :rake, :task do |t, args|
    each_heroku_app do |name, app, repo|
      system_with_echo "heroku rake --app #{app} #{args[:task]}"
    end
  end
end

desc "Deploys the given commit, migrates and restarts (default: HEAD)"
task :deploy, :commit, :needs => :before_deploy do |t, args|
  args.with_defaults(:commit => "HEAD")
  system_with_echo "git update-ref refs/heroku_san/deploy #{args[:commit]}"
  each_heroku_app do |name, app, repo|
    @git_push_arguments ||= []
    system_with_echo "git push #{repo} #{@git_push_arguments.join(' ')} refs/heroku_san/deploy:master && heroku rake --app #{app} db:migrate && heroku restart --app #{app}"
  end
  system_with_echo "git update-ref -d refs/heroku_san/deploy"
  Rake::Task[:after_deploy].execute
end

namespace :deploy do
  desc "Force-deploys the given commit, migrates and restarts (default: HEAD)"
  task :force, :commit do |t, args|
    @git_push_arguments ||= []
    @git_push_arguments << '--force'
    Rake::Task[:deploy].execute(args)
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
    system_with_echo "heroku bundles:capture --app #{app}"
  end
end

desc "Opens a remote console"
task :console do
  each_heroku_app do |name, app, repo|
    system_with_echo "heroku console --app #{app}"
  end
end

desc "Restarts remote servers"
task :restart do
  each_heroku_app do |name, app, repo|
    system_with_echo "heroku restart --app #{app}"
  end
end

desc "Migrates and restarts remote servers"
task :migrate do
  each_heroku_app do |name, app, repo|
    system_with_echo "heroku rake --app #{app} db:migrate && heroku restart --app #{app}"
  end
end

namespace :db do
  task :pull do
    each_heroku_app do |name, app, repo|
      system_with_echo "heroku pgdumps:capture --app #{app}"
      dump = `heroku pgdumps --app #{app}`.split("\n").last.split(" ").first
      system_with_echo "mkdir -p #{Rails.root}/db/dumps"
      file = "#{Rails.root}/db/dumps/#{dump}.sql.gz"
      url = `heroku pgdumps:url --app #{app} #{dump}`.chomp
      system_with_echo "wget", url, "-O", file
      system_with_echo "rake db:drop db:create"
      system_with_echo "gunzip -c #{file} | #{Rails.root}/script/dbconsole"
      system_with_echo "rake jobs:clear"
    end
  end
end

def system_with_echo(*args)
  puts args.join(' ')
  system(*args)
end

def each_heroku_app
  if @heroku_apps.blank? && HEROKU_SETTINGS['apps'].size == 1
    app = HEROKU_SETTINGS['apps'].keys.first
    puts "Defaulting to #{app} app since only one app is defined"
    @heroku_apps = [app]
  end
  if @heroku_apps.present?
    @heroku_apps.each do |name|
      app = HEROKU_SETTINGS['apps'][name]
      yield(name, app, "git@heroku.com:#{app}.git")
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
