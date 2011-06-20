require 'heroku_san/git'
include Git

@heroku_san = HerokuSan.new(Rails.root.join('config', 'heroku.yml'))

@heroku_san.all.each do |name|
  desc "Select #{name} Heroku app for later commands"
  task name do
    @heroku_san << name
  end
end

desc 'Select all Heroku apps for later command'
task :all do
  @heroku_san << @heroku_san.all
end

namespace :heroku do
  desc "Creates the Heroku app"
  task :create do
    each_heroku_app do |name, app, repo|
      sh "heroku create #{app}"
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
      sh "git remote add #{name} #{repo}"
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
    desc 'Lists configured apps without hitting heroku'
    task :local => :all do
      each_heroku_app do |name, app, repo|
        puts "#{name} is shorthand for the Heroku app #{app} located at:"
        puts "  #{repo}"
        tag = tag(name)
        puts "  the #{name} TAG is '#{tag}'" if tag
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
      sh "heroku run --app #{app} rake #{args[:task]}"
    end
  end

  desc "Pushes the given commit (default: HEAD)"
  task :push, :commit do |t, args|
    each_heroku_app do |name, app, repo|
      git_push(args[:commit] || git_tag(tag(name)), repo)
    end
  end

  namespace :push do
    desc "Force-pushes the given commit (default: HEAD)"
    task :force, :commit do |t, args|
      each_heroku_app do |name, app, repo|
        git_push(args[:commit] || git_tag(tag(name)), repo, %w[--force])
      end
    end
  end

  desc "Enable maintenance mode"
  task :maintenance do
    each_heroku_app do |name, app|
      @heroku_san.maintenance(app, 'on')
    end
  end

  desc "Enable maintenance mode"
  task :maintenance_on do
    each_heroku_app do |name, app|
      @heroku_san.maintenance(app, 'on')
    end
  end

  desc "Disable maintenance mode"
  task :maintenance_off do
    each_heroku_app do |name, app|
      @heroku_san.maintenance(app, 'off')
    end
  end
end

desc "Pushes the given commit, migrates and restarts (default: HEAD)"
task :deploy, [:commit] => [:before_deploy] do |t, args|
  each_heroku_app do |name, app, repo|
    git_push(args[:commit] || git_tag(tag(name)), repo)
    @heroku_san.migrate(app)
  end
  Rake::Task[:after_deploy].execute
end

namespace :deploy do
  desc "Force-pushes the given commit, migrates and restarts (default: HEAD)"
  task :force, [:commit] => [:before_deploy] do |t, args|
    each_heroku_app do |name, app, repo|
      git_push(args[:commit] || git_tag(tag(name)), repo, %w[--force])
      @heroku_san.migrate(app)
    end
    Rake::Task[:after_deploy].execute
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
    sh "heroku console --app #{app}"
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
    @heroku_san.migrate(app)
  end
end

desc "Shows the Heroku logs"
task :logs do
  each_heroku_app do |name, app, repo|
    sh "heroku logs --app #{app}"
  end
end

namespace :db do
  task :pull do
    each_heroku_app do |name, app, repo|
      sh "heroku pgdumps:capture --app #{app}"
      dump = `heroku pgdumps --app #{app}`.split("\n").last.split(" ").first
      sh "mkdir -p #{Rails.root}/db/dumps"
      file = "#{Rails.root}/db/dumps/#{dump}.sql.gz"
      url = `heroku pgdumps:url --app #{app} #{dump}`.chomp
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

def tag(app)
  tag = @heroku_san.app_settings[app]['tag']
end
