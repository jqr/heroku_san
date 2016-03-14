require 'active_support/core_ext/string/strip'
require 'godot'
require 'bundler'

Given /^I have a new Rails project$/ do
  cmd = "rails new test_app --quiet --force --skip-javascript --skip-test-unit --skip-sprockets --skip-active-record"
  run_simple cmd, exit_timeout: 120

  cd '/test_app'

  run_simple 'git init .'
end

Given /^I have a new Sinatra project$/ do
  create_directory 'test_app'
  cd '/test_app'

  run_simple 'git init .'

  create_directory 'config'
  write_file 'app.rb', <<-EOT.strip_heredoc
    require 'sinatra'

    get '/' do
      'Hello, world.'
    end
  EOT

  write_file 'config.ru', <<-EOT.strip_heredoc
    require './app'
    run Sinatra::Application
  EOT

  write_file 'Gemfile', <<-EOT.strip_heredoc
    source 'https://rubygems.org'
    ruby '#{ruby_version}'
    gem 'sinatra'
    group :development, :test do
      gem 'heroku_san', :path => '../../../.'
    end
  EOT

  write_file 'Rakefile', <<-EOT.strip_heredoc
    require "bundler/setup"
    require "heroku_san"
    config_file = File.join(File.expand_path(File.dirname(__FILE__)), 'config', 'heroku.yml')
    HerokuSan.project = HerokuSan::Project.new(config_file, :deploy => HerokuSan::Deploy::Sinatra)
    load "heroku_san/tasks.rb"
  EOT

  Bundler.with_clean_env do
    run_simple 'bundle install'
  end
end

When /^I commit .* changes with "(.*)"$/ do |message|
  run_simple 'git add .'
  run_simple "git commit -m '#{message}'"
end

When /^I tag the commit with "([^"]*)" annotated by "([^"]*)"$/ do |tag, annotation|
  run_simple "git tag -a '#{tag}' -m '#{annotation}' HEAD"
end

When /^I add heroku_san to the rails Gemfile$/ do
  overwrite_file 'Gemfile', <<-EOT.strip_heredoc
    source 'https://rubygems.org'
    ruby '#{ruby_version}'
    gem 'rails', '4.2.6'
    group :development, :test do
      gem 'heroku_san', :path => '../../../.'
    end
  EOT
  Bundler.with_clean_env do
    run_simple 'bundle install'
  end
  run_simple "git commit -m 'Add heroku_san gem'"
end

When /^I add heroku_san to the sinatra Gemfile$/ do
end

When /^I run bundle install$/ do
  Bundler.with_clean_env do
    run_simple 'bundle install', exit_timeout: 60
  end
  expect(%w[Gemfile.lock]).to Aruba::Matchers.all be_an_existing_file
end

Then /^rake reports that the heroku: tasks are available$/ do
  run_simple 'rake -T heroku:'
  expect(last_command_started).to have_output /rake heroku:apps/
end

When /^I generate a new config file$/ do
  run_simple 'rails generate heroku_san'
  expect(last_command_started).to have_output /create  config\/heroku\.yml/
  overwrite_simple_config_file
end

When /^I create a new config\/heroku\.yml file$/ do
  run_simple 'rake heroku:create_config'
  expect(last_command_started).to have_output /Copied example config to ".*\/config\/heroku\.yml"/
  expect(last_command_started).to have_output /Please edit ".*\/config\/heroku\.yml" with your application's settings\./
  overwrite_simple_config_file
end

When /^I create my project on Heroku$/ do
  run_simple 'rake test_app heroku:create'
  expect(last_command_started).to have_output /test_app: Created ([\w-]+)/

  output = last_command_started.output
  @app = output.match(/test_app: Created ([\w-]+)/)[1]
  at_exit { system "heroku apps:destroy #{@app} --confirm #{@app}" }
  overwrite_file 'config/heroku.yml', <<-EOT.strip_heredoc
    ---
    test_app:
      app: #{@app}

  EOT
end

When /^I curl the app home page$/ do
  expect(vladimir.match %r{<h1><strong>Heroku | Welcome to your new app!</strong></h1>}).to be, "Heroku didn't spin up a new app"
end

When /^I configure my project$/ do
  overwrite_file 'config/heroku.yml', <<EOT.strip_heredoc
    ---
    test_app:
      app: #{@app}
      config:
        DROIDS: marvin

EOT
  cmd = 'rake test_app heroku:config'
  run_simple cmd
  expect(last_command_started).to have_output /DROIDS: marvin/
end

When /^I turn maintenance on$/ do
  run_simple 'rake test_app heroku:maintenance_on'
  expect(last_command_started).to have_output /test_app: Maintenance mode enabled\./

  expect(vladimir.match %r{<title>Offline for Maintenance</title>}).to be, "App is not offline"
end

When /^I turn maintenance off$/ do
  run_simple 'rake test_app heroku:maintenance_off'
  expect(last_command_started).to have_output /test_app: Maintenance mode disabled\./
  assert_app_is_running
end

When /^I restart my project$/ do
  run_simple 'rake test_app heroku:restart'
  expect(last_command_started).to have_output /test_app: Restarted\./
  assert_app_is_running
end

When /^I generate a scaffold$/ do
  run_simple 'rails generate resource droid'
  append_to_file 'app/views/droids/index.html.erb', %Q{\n<div><code><%= ENV['DROIDS'] -%></code></div>\n}
end

When /^I add a new action$/ do
  append_to_file 'app.rb', <<'EOT'.strip_heredoc

    get '/droids' do
      "<div><code>#{ENV['DROIDS']}</code></div>"
    end
EOT
end

When /^I deploy my project$/ do
  run_simple 'rake test_app deploy', exit_timeout: 180
  expect(last_command_started).to have_output /https:\/\/#{@app}\.herokuapp\.com\/ deployed to Heroku/
end

When /^I deploy to tag "([^"]*)"$/ do |tag|
  run_simple "rake test_app deploy[#{tag}]", exit_timeout: 180
  expect(last_command_started).to have_output /https:\/\/#{@app}\.herokuapp\.com\/ deployed to Heroku/
end

When /^I list all apps on Heroku$/ do
  sha = cd('.') { `git rev-parse HEAD`.chomp }
  run_simple 'rake heroku:apps'
  expect(last_command_started).to have_output /test_app is shorthand for the Heroku app #{@app} located at:/
  expect(last_command_started).to have_output /https:\/\/git\.heroku\.com\/#{@app}\.git/
  expect(last_command_started).to have_output /@ #{sha} master/
end

When /^I install an addon$/ do
  overwrite_file 'config/heroku.yml', <<END_CONFIG.strip_heredoc
    test_app:
      app: #{@app}
      addons:
        - deployhooks:email

END_CONFIG

  run_simple 'rake test_app heroku:addons'
  # The output should show the new one ...
  expect(last_command_started).to have_output /deployhooks:email/
end

Then /^(?:heroku_san|issue \d+) (?:is green|has been fixed)$/ do
  run_simple "heroku apps:destroy #{@app} --confirm #{@app}"
end

def assert_app_is_running
  expect(vladimir.match %r{<code>marvin</code>}, 'droids').to be, "http://#{@app}.herokuapp.com/droids are not the droids I'm looking for"
end

def vladimir
  @vladimir ||= begin
    Godot.new("#{@app}.herokuapp.com", 80).tap do |vladimir|
      vladimir.timeout = 60
      vladimir.interval = 5
    end
  end
end

def overwrite_simple_config_file
  overwrite_file 'config/heroku.yml', <<EOT.strip_heredoc
    ---
    test_app: 
    
EOT
end

def ruby_version
  ENV['TRAVIS_RUBY_VERSION'] || '2.2.4'
end
