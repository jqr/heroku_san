require 'heroku_san'
require 'heroku_san/git'
include HerokuSan::Git

if defined?(Rails)
  HerokuSan.project ||= HerokuSan::Project.new(
                          Rails.root.join("config", "heroku.yml"),
                          :deploy => HerokuSan::Deploy::Rails
                          )
end

HerokuSan.project.all.each do |stage|
  desc "Select #{stage} Heroku app for later commands"
  task "heroku:stage:#{stage}" do
    HerokuSan.project << stage
  end
  task stage => "heroku:stage:#{stage}"
end

namespace :heroku do
  desc 'Select all Heroku apps for later command'
  task 'stage:all' do
    HerokuSan.project << HerokuSan.project.all
  end

  desc "Creates the Heroku app"
  task :create do
    each_heroku_app do |stage|
      puts "#{stage.name}: Created #{stage.create}"
    end
  end

  #desc "Generate the Heroku gems manifest from gem dependencies"
  task :gems => 'gems:base' do
    raise HerokuSan::Deprecated
  end

  desc 'Add git remotes for all apps in this project'
  task :remotes do
    each_heroku_app do |stage|
      sh "git remote add #{stage.name} #{stage.repo}"
    end
  end

  task :share do
    raise HerokuSan::Deprecated
  end

  task :unshare do
    raise HerokuSan::Deprecated
  end

  desc 'Lists configured apps'
  task :apps => :all do
    each_heroku_app do |stage|
      rev = stage.revision
      puts  "#{stage.name} is shorthand for the Heroku app #{stage.app} located at:"
      puts  "  #{stage.repo}"
      puts  "  @ #{(rev == '') ? 'not deployed' : rev}"
      puts
    end
  end

  namespace :apps do
    desc 'Lists configured apps without hitting heroku'
    task :local => :all do
      each_heroku_app do |stage|
        puts "#{stage.name} is shorthand for the Heroku app #{stage.app} located at:"
        puts "  #{stage.repo}"
        puts "  the #{stage.name} TAG is '#{stage.tag}'" if stage.tag
        puts
      end
    end
  end

  desc 'Add config:vars to each application.'
  task :config do
    each_heroku_app do |stage|
      stage.push_config.each do |(key,value)|
        puts "#{key}: #{value}"
      end
    end
  end

  desc 'Install addons for the application.'
  task :addons do
    each_heroku_app do |stage|
      addons = stage.install_addons
      puts "#{stage.name} addons"
      addons.each do |addon| 
        puts "  - " + addon['name'] + (addon['configured'] ? "" : " # Configure at https://api.heroku.com/myapps/#{stage.app}/addons/#{addon['name']}")
      end
    end
  end

  namespace :addons do
    desc 'List configured addons, without installing them'
    task :local do
      each_heroku_app do |stage|
        puts "Configured addons for #{stage.name}:"
        stage.addons.each do |addon|
          puts "  - #{addon}"
        end
      end
    end
  end

  desc 'Creates an example configuration file'
  task :create_config do
    filename = %Q{#{HerokuSan.project.config_file.to_s}}
    if HerokuSan.project.create_config
      puts "Copied example config to #{filename.inspect}"
      if ENV['EDITOR'] && ENV['EDITOR'] != ''
        sh "#{ENV['EDITOR']} #{filename}"
      else
        puts "Please edit #{filename.inspect} with your application's settings."
      end
    else
      puts "#{filename.inspect} already exists"
    end
  end

  namespace :config do
    desc 'Add proper RACK_ENV to each application'
    task :rack_env => :all do
      each_heroku_app do |stage|
        command = "heroku config --app #{stage.app}"
        puts command
        config = Hash[`#{command}`.scan(/^(.+?)\s*=>\s*(.+)$/)]
        if config['RACK_ENV'] != stage.name
          puts stage.push_config 'RACK_ENV' => stage.name
        end
      end
    end

    desc "Lists config variables as set on Heroku"
    task :list do
      each_heroku_app do |stage|
        puts "#{stage.name}:"
        stage.long_config.each do |(key,value)|
          puts "#{key}: #{value}"
        end
      end
    end

    namespace :list do
      desc "Lists local config variables without setting them"
      task :local do
        each_heroku_app do |stage|
          puts "#{stage.name}:"
          stage.config.each do |(key,value)|
            puts "#{key}: #{value}"
          end
        end
      end
    end
  end

  desc 'Runs a rake task remotely'
  task :rake, [:task] do |t, args|
    each_heroku_app do |stage|
      puts stage.run "rake #{args.task}"
    end
  end

  desc "Pushes the given commit (default: HEAD)"
  task :push, :commit do |t, args|
    each_heroku_app do |stage|
      stage.push(args.commit)
    end
  end

  namespace :push do
    desc "Force-pushes the given commit (default: HEAD)"
    task :force, :commit do |t, args|
      each_heroku_app do |stage|
        stage.push(args.commit, :force)
      end
    end
  end

  desc "Enable maintenance mode"
  task :maintenance do
    each_heroku_app do |stage|
      stage.maintenance :on
      puts "#{stage.name}: Maintenance mode enabled."
    end
  end

  desc "Enable maintenance mode"
  task :maintenance_on do
    each_heroku_app do |stage|
      stage.maintenance :on
      puts "#{stage.name}: Maintenance mode enabled."
    end
  end

  desc "Disable maintenance mode"
  task :maintenance_off do
    each_heroku_app do |stage|
      stage.maintenance :off
      puts "#{stage.name}: Maintenance mode disabled."
    end
  end

  desc "Deploys the app (default: HEAD)"
  task :deploy, [:commit] => [:before_deploy] do |t, args|
    each_heroku_app do |stage|
      stage.deploy(args.commit)
    end
    Rake::Task[:after_deploy].execute
  end

  namespace :deploy do
    desc "Deploys the app with push --force (default: HEAD)"
    task :force, [:commit] => [:before_deploy] do |t, args|
      each_heroku_app do |stage|
        stage.deploy(args.commit, :force)
      end
      Rake::Task[:after_deploy].execute
    end

    desc "Callback before deploys"
    task :before do
    end

    desc "Callback after deploys"
    task :after do
  end

  end

  task :force_deploy do
    raise HerokuSan::Deprecated
  end

  #desc "Captures a bundle on Heroku"
  task :capture do
    raise HerokuSan::Deprecated
  end

  desc "Opens a remote console"
  task :console do
    each_heroku_app do |stage|
      stage.run 'console'
    end
  end

  desc "Restarts remote servers"
  task :restart do
    each_heroku_app do |stage|
      stage.restart
      puts "#{stage.name}: Restarted."
    end
  end

  namespace :logs do
    task :default do
      each_heroku_app do |stage|
        stage.logs
      end
    end

    desc "Tail the Heroku logs (requires logging:expanded)"
    task :tail do
      each_heroku_app do |stage|
        stage.logs(:tail)
      end
    end
  end

  desc "Shows the Heroku logs"
  task :logs => 'logs:default'

  namespace :db do
    desc "Migrates and restarts remote servers"
    task :migrate do
      each_heroku_app do |stage|
        stage.migrate
      end
    end

    desc "Pull database from stage to local dev database"
    task :pull do
      each_heroku_app do |stage|
        sh "heroku db:pull --app #{stage.app} --confirm #{stage.app}"
      end
    end
  end

  desc "Run a bash shell on Heroku"
  task :shell do
    each_heroku_app do |stage|
      stage.run 'bash'
    end
  end
end


def alias_task(hash)
  hash.each_pair do |(new_task, original_task)|
    the_task = Rake.application[original_task]
    task new_task, {the_task.arg_names => [original_task]}
  end
end

alias_task :all => 'heroku:stage:all'
alias_task :deploy => 'heroku:deploy'
alias_task 'deploy:force' => 'heroku:deploy:force'
alias_task :before_deploy => 'heroku:deploy:before'
alias_task :after_deploy => 'heroku:deploy:after'
alias_task :console => 'heroku:console'
alias_task :restart => 'heroku:restart'
alias_task :migrate => 'heroku:db:migrate'
alias_task :logs => 'heroku:logs:default'
alias_task 'logs:tail' => 'heroku:logs:tail'
alias_task 'heroku:rack_env' => 'heroku:config:rack_env'
alias_task :shell => 'heroku:shell'

def each_heroku_app(&block)
  Bundler.with_clean_env do
    HerokuSan.project.each_app(&block)
  end
  puts
rescue HerokuSan::NoApps => e
  puts "You must first specify at least one Heroku app:
    rake <app> [<app>] <command>
    rake production restart
    rake demo staging deploy"

  puts "\nYou can use also command all Heroku apps for this project:
    rake all restart"

  exit(1)
end
