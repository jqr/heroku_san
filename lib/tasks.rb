require 'git'
include Git

@heroku_san = HerokuSan::Project.new(Rails.root.join('config', 'heroku.yml'))

@heroku_san.all.each do |stage|
  desc "Select #{stage} Heroku app for later commands"
  task "heroku:stage:#{stage}" do
    @heroku_san << stage
  end
  task stage => "heroku:stage:#{stage}"
end

namespace :heroku do
  desc 'Select all Heroku apps for later command'
  task 'stage:all' do
    @heroku_san << @heroku_san.all
  end
  
  desc "Creates the Heroku app"
  task :create do
    each_heroku_app do |stage|
      stage.create
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

  desc 'Adds a collaborator (asks for email)'
  task :share do
    print "Email address of collaborator to add: "
    $stdout.flush
    email = $stdin.gets
    each_heroku_app do |stage|
      stage.sharing_add email
    end
  end

  desc 'Removes a collaborator (asks for email)'
  task :unshare do
    print "Email address of collaborator to remove: "
    $stdout.flush
    email = $stdin.gets
    each_heroku_app do |stage|
      stage.sharing_remove email
    end
  end

  desc 'Lists configured apps'
  task :apps => :all do
    each_heroku_app do |stage|
      rev = stage.revision
      puts  "#{stage.name} is shorthand for the Heroku app #{stage.app} located at:"
      puts  "  #{stage.repo}"
      puts  "  @ #{rev.blank? ? 'not deployed' : rev}"
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
      stage.push_config
    end
  end

  desc 'Creates an example configuration file'
  task :create_config do
    filename = %Q{#{@heroku_san.config_file.to_s}}
    if @heroku_san.create_config
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
          stage.push_config RACK_ENV: stage.name
        end
      end
    end

    desc "Lists config variables as set on Heroku"
    task :list do
      each_heroku_app do |stage|
        puts "#{stage.name}:"
        stage.long_config
      end
    end

    namespace :list do
      desc "Lists local config variables without setting them"
      task :local do
        each_heroku_app do |stage|
          (stage.config).each do |var, value|
            puts "#{stage.name} #{var}: '#{value}'"
          end
        end
      end
    end
  end
  
  desc 'Runs a rake task remotely'
  task :rake, [:task] do |t, args|
    each_heroku_app do |stage|
      stage.run 'rake', args.task
    end
  end

  desc "Pushes the given commit (default: HEAD)"
  task :push, :commit do |t, args|
    each_heroku_app do |stage|
      stage.deploy(args[:commit])
    end
  end

  namespace :push do
    desc "Force-pushes the given commit (default: HEAD)"
    task :force, :commit do |t, args|
      each_heroku_app do |stage|
        stage.deploy(args[:commit], :force)
      end
    end
  end

  desc "Enable maintenance mode"
  task :maintenance do
    each_heroku_app do |stage|
      stage.maintenance :on
    end
  end

  desc "Enable maintenance mode"
  task :maintenance_on do
    each_heroku_app do |stage|
      stage.maintenance :on
    end
  end

  desc "Disable maintenance mode"
  task :maintenance_off do
    each_heroku_app do |stage|
      stage.maintenance :off
    end
  end

  desc "Pushes the given commit, migrates and restarts (default: HEAD)"
  task :deploy, [:commit] => [:before_deploy] do |t, args|
    each_heroku_app do |stage|
      stage.deploy(args[:commit])
      stage.migrate
    end
    Rake::Task[:after_deploy].execute
  end

  namespace :deploy do
    desc "Force-pushes the given commit, migrates and restarts (default: HEAD)"
    task :force, [:commit] => [:before_deploy] do |t, args|
      each_heroku_app do |stage|
        stage.deploy(args[:commit], :force)
        stage.migrate
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
        sh "heroku pgdumps:capture --app #{stage.app}"
        dump = `heroku pgdumps --app #{stage.app}`.split("\n").last.split(" ").first
        sh "mkdir -p #{Rails.root}/db/dumps"
        file = "#{Rails.root}/db/dumps/#{dump}.sql.gz"
        url = `heroku pgdumps:url --app #{stage.app} #{dump}`.chomp
        sh "wget", url, "-O", file
        sh "rake db:drop db:create"
        sh "gunzip -c #{file} | #{Rails.root}/script/dbconsole"
        sh "rake jobs:clear"
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

task :all => 'heroku:stage:all'
task :deploy => 'heroku:deploy'
task 'deploy:force' => 'heroku:deploy:force'
task :before_deploy => 'heroku:deploy:before'
task :after_deploy => 'heroku:deploy:after'
task :console => 'heroku:console'
task :restart => 'heroku:restart'
task :migrate => 'heroku:db:migrate'
task :logs => 'heroku:logs:default'
task 'logs:tail' => 'heroku:logs:tail'
task 'heroku:rack_env' => 'heroku:config:rack_env'
task :shell => 'heroku:shell'

def each_heroku_app(&block)
  @heroku_san.each_app(&block)
  puts
rescue HerokuSan::NoApps => e
  puts "You must first specify at least one Heroku app:
    rake <app> [<app>] <command>
    rake production restart
    rake demo staging deploy"

  puts "\nYou can use also command all Heroku apps for this project:
    rake all heroku:share"

  exit(1)
end