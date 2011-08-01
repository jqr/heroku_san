require 'heroku_san/git'
include Git

@heroku_san = HerokuSan.new(Rails.root.join('config', 'heroku.yml'))

@heroku_san.all.each do |stage|
  desc "Select #{stage} Heroku app for later commands"
  task stage do
    @heroku_san << stage
  end
end

desc 'Select all Heroku apps for later command'
task :all do
  @heroku_san << @heroku_san.all
end

namespace :heroku do
  desc "Creates the Heroku app"
  task :create do
    each_heroku_app do |stage, repo, config|
      @heroku_san.create(stage)
    end
  end

  desc "Generate the Heroku gems manifest from gem dependencies"
  task :gems => 'gems:base' do
    raise HerokuSan::Deprecated
  end

  desc 'Add git remotes for all apps in this project'
  task :remotes do
    each_heroku_app do |stage, repo, config|
      sh "git remote add #{stage} #{repo}"
    end
  end

  desc 'Adds a collaborator'
  task :share do
    print "Email address of collaborator to add: "
    $stdout.flush
    email = $stdin.gets
    each_heroku_app do |stage, repo, config|
      @heroku_san.sharing_add(stage, email)
    end
  end

  desc 'Removes a collaborator'
  task :unshare do
    print "Email address of collaborator to remove: "
    $stdout.flush
    email = $stdin.gets
    each_heroku_app do |stage, repo, config|
      @heroku_san.sharing_remove(stage, email)
    end
  end

  desc 'Lists configured apps'
  task :apps => :all do
    each_heroku_app do |stage, repo, config|
      puts  "#{stage} is shorthand for the Heroku app #{@heroku_san[stage]['app']} located at:"
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
    desc 'Lists configured apps without hitting heroku'
    task :local => :all do
      each_heroku_app do |stage, repo, config|
        puts "#{stage} is shorthand for the Heroku app #{@heroku_san[stage]['app']} located at:"
        puts "  #{repo}"
        tag = @heroku_san[stage]['tag']
        puts "  the #{stage} TAG is '#{tag}'" if tag
        puts
      end
    end
  end

  desc 'Add proper RACK_ENV to each application'
  task :rack_env => :all do
    each_heroku_app do |stage, repo, config|
      command = "heroku config --app #{@heroku_san[stage]['app']}"
      puts command
      config = Hash[`#{command}`.scan(/^(.+?)\s*=>\s*(.+)$/)]
      if config['RACK_ENV'] != stage
        sh "heroku config:add --app #{@heroku_san[stage]['app']} RACK_ENV=#{stage}"
      end
    end
  end

  desc 'Creates an example configuration file'
  task :create_config do
    filename = %Q{#{@heroku_san.config_file.to_s}}
    if @heroku_san.create_config
      puts "Copied example config to #{filename.inspect}"
      if ENV['EDITOR'].present?
        sh "#{ENV['EDITOR']} #{filename}"
      else
        puts "Please edit #{filename.inspect} with your application's settings."
      end
    else
      puts "#{filename.inspect} already exists"
    end
  end

  desc 'Add config:vars to each application.'
  task :config do
    each_heroku_app do |stage, repo, config|
      command = "heroku config:add --app #{@heroku_san[stage]['app']}"
      config.each do |var, value|
        command += " #{var}=#{value}"
      end
      sh(command)
    end
  end

  namespace :config do
    desc "Lists config variables as set on Heroku"
    task :list do
      each_heroku_app do |stage, repo, config|
        puts "#{stage}:"
        @heroku_san.long_config(stage)
      end
    end

    namespace :list do
      desc "Lists local config variables without setting them"
      task :local do
        each_heroku_app do |stage, repo, config|
          (config).each do |var, value|
            puts "#{stage} #{var}: '#{value}'"
          end
        end
      end
    end
  end
  
  desc 'Runs a rake task remotely'
  task :rake, [:task] do |t, args|
    each_heroku_app do |stage, repo, config|
      @heroku_san.run(stage, 'rake', args.task)
    end
  end

  desc "Pushes the given commit (default: HEAD)"
  task :push, :commit do |t, args|
    each_heroku_app do |stage, repo, config|
      git_push(args[:commit] || git_parsed_tag(@heroku_san[stage]['tag']), repo)
    end
  end

  namespace :push do
    desc "Force-pushes the given commit (default: HEAD)"
    task :force, :commit do |t, args|
      each_heroku_app do |stage, repo, config|
        git_push(args[:commit] || git_parsed_tag(@heroku_san[stage]['tag']), repo, %w[--force])
      end
    end
  end

  desc "Enable maintenance mode"
  task :maintenance do
    each_heroku_app do |stage, repo, config|
      @heroku_san.maintenance(stage, :on)
    end
  end

  desc "Enable maintenance mode"
  task :maintenance_on do
    each_heroku_app do |stage, repo, config|
      @heroku_san.maintenance(stage, :on)
    end
  end

  desc "Disable maintenance mode"
  task :maintenance_off do
    each_heroku_app do |stage, repo, config|
      @heroku_san.maintenance(stage, :off)
    end
  end
end

desc "Pushes the given commit, migrates and restarts (default: HEAD)"
task :deploy, [:commit] => [:before_deploy] do |t, args|
  each_heroku_app do |stage, repo, config|
    git_push(args[:commit] || git_parsed_tag(@heroku_san[stage]['tag']), repo)
    @heroku_san.migrate(stage)
  end
  Rake::Task[:after_deploy].execute
end

namespace :deploy do
  desc "Force-pushes the given commit, migrates and restarts (default: HEAD)"
  task :force, [:commit] => [:before_deploy] do |t, args|
    each_heroku_app do |stage, repo, config|
      git_push(args[:commit] || git_parsed_tag(@heroku_san[stage]['tag']), repo, %w[--force])
      @heroku_san.migrate(stage)
    end
    Rake::Task[:after_deploy].execute
  end
end

task :force_deploy do
  raise Deprecated
end

desc "Callback before deploys"
task :before_deploy do
end

desc "Callback after deploys"
task :after_deploy do
end

desc "Captures a bundle on Heroku"
task :capture do
  each_heroku_app do |stage, repo, config|
    @heroku_san.capture(stage)
  end
end

desc "Opens a remote console"
task :console do
  each_heroku_app do |stage, repo, config|
    @heroku_san.run(stage, 'console')
  end
end

desc "Restarts remote servers"
task :restart do
  each_heroku_app do |stage, repo, config|
    @heroku_san.restart(stage)
  end
end

desc "Migrates and restarts remote servers"
task :migrate do
  each_heroku_app do |stage, repo, config|
    @heroku_san.migrate(stage)
  end
end

desc "Shows the Heroku logs"
task :logs do
  each_heroku_app do |stage, repo, config|
    @heroku_san.logs(stage)
  end
end

namespace :db do
  task :pull do
    each_heroku_app do |stage, repo, config|
      sh "heroku pgdumps:capture --app #{@heroku_san[stage]['app']}"
      dump = `heroku pgdumps --app #{@heroku_san[stage]['app']}`.split("\n").last.split(" ").first
      sh "mkdir -p #{Rails.root}/db/dumps"
      file = "#{Rails.root}/db/dumps/#{dump}.sql.gz"
      url = `heroku pgdumps:url --app #{@heroku_san[stage]['app']} #{dump}`.chomp
      sh "wget", url, "-O", file
      sh "rake db:drop db:create"
      sh "gunzip -c #{file} | #{Rails.root}/script/dbconsole"
      sh "rake jobs:clear"
    end
  end
end

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