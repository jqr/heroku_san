World(Aruba::Api)
require 'active_support/core_ext/string/strip'
require 'godot'

Given /^I have a new Rails project$/ do
  cmd = "rails new test_app --quiet --force --skip-bundle --skip-javascript --skip-test-unit --skip-sprockets"
  run_clean unescape(cmd)
end

Given /^I have a new Sinatra project$/ do
  create_dir 'test_app/config'
  write_file 'test_app/app.rb', <<-EOT.strip_heredoc
    require 'sinatra'

    get '/' do
      'Hello, world.'
    end
  EOT

  write_file 'test_app/config.ru', <<-EOT.strip_heredoc
    require './app'
    run Sinatra::Application
  EOT

  write_file 'test_app/Gemfile', <<-EOT.strip_heredoc
    source 'http://rubygems.org'
    gem 'sinatra'
  EOT

  write_file 'test_app/Rakefile', <<-EOT.strip_heredoc
    require "bundler/setup"
    require "heroku_san"
    config_file = File.join(File.expand_path(File.dirname(__FILE__)), 'config', 'heroku.yml')
    HerokuSan.project = HerokuSan::Project.new(config_file, :deploy => HerokuSan::Deploy::Sinatra)
    load "heroku_san/tasks.rb"
  EOT

end

When /^I am in the project directory$/ do
  cd '/test_app'
  run_clean 'git init .'
end

When /^I commit .* changes with "(.*)"$/ do |message|
  run_clean 'git add .'
  run_clean "git commit -m '#{message}'"
end

When /^I tag the commit with "([^"]*)" annotated by "([^"]*)"$/ do |tag, annotation|
  run_clean "git tag -a '#{tag}' -m '#{annotation}' HEAD"
end

When /^I add heroku_san to the rails Gemfile$/ do
  overwrite_file 'Gemfile', <<EOT.strip_heredoc
    source 'https://rubygems.org'
    ruby '#{ruby_version}'
    gem 'rails', '3.2.7'
    gem 'pg'
    group :development, :test do
      gem 'heroku_san', :path => '../../../.'
      gem 'sqlite3'
    end
EOT
end

When /^I add heroku_san to the sinatra Gemfile$/ do
  overwrite_file 'Gemfile', <<EOT.strip_heredoc
    source 'https://rubygems.org'
    ruby '#{ruby_version}'
    gem 'sinatra'
    group :development, :test do
      gem 'heroku_san', :path => '../../../.'
    end
EOT
end

def run_clean(cmd)
  Bundler.with_clean_env do
    ENV['NOEXEC_DISABLE'] = '1'
    run_simple cmd
  end
  stdout_from cmd
end

When /^I run bundle install$/ do
  run_clean "bundle install"
end

When /^I cleanly run `([^`]*)`$/ do |cmd|
  run_clean(cmd)
end

Then /^rake reports that the heroku: tasks are available$/ do
  output = run_clean 'rake -T heroku:'
  assert_partial_output 'rake heroku:apps', output
end

When /^I generate a new config file$/ do
  run_clean 'rails generate heroku_san'
  output = stdout_from 'rails generate heroku_san'
  assert_partial_output 'create  config/heroku.yml', output
  overwrite_simple_config_file
end

When /^I create a new config\/heroku\.yml file$/ do
  output = run_clean 'rake heroku:create_config'
  assert_matching_output %q{Copied example config to ".*.config.heroku.yml"}, output
  assert_matching_output %q{Please edit ".*.config.heroku.yml" with your application's settings.}, output
  overwrite_simple_config_file
end

When /^I create my project on Heroku$/ do
  cmd = 'rake test_app heroku:create'
  output = run_clean unescape(cmd)
  assert_matching_output %q{test_app: Created ([\w-]+)}, output
  
  @app = output.match(/test_app: Created ([\w-]+)/)[1]
  overwrite_file 'config/heroku.yml', <<EOT.strip_heredoc
    ---
    test_app:
      app: #{@app}

EOT
end

When /^I curl the app home page$/ do
  vladimir.match(%r{<h1><strong>Heroku | Welcome to your new app!</strong></h1>}).should be, "Heroku didn't spin up a new app"
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
  output = run_clean cmd
  assert_partial_output 'DROIDS: marvin', output
end

When /^I turn maintenance on$/ do
  output = run_clean 'rake test_app heroku:maintenance_on'
  assert_partial_output 'test_app: Maintenance mode enabled.', output

  vladimir.match(%r{<title>Offline for Maintenance</title>}).should be, "App is not offline"
end

When /^I turn maintenance off$/ do
  output = run_clean 'rake test_app heroku:maintenance_off'
  assert_partial_output 'test_app: Maintenance mode disabled.', output
  assert_app_is_running
end

When /^I restart my project$/ do
  output = run_clean 'rake test_app heroku:restart'
  assert_partial_output 'test_app: Restarted.', output
  assert_app_is_running
end

When /^I generate a scaffold$/ do
  run_clean 'rails generate resource droid'
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
  run_clean 'rake test_app deploy'
  assert_partial_output "http://#{@app}.herokuapp.com deployed to Heroku", all_output
end

When /^I deploy to tag "([^"]*)"$/ do |tag|
  run_clean "rake test_app deploy[#{tag}]"
  assert_partial_output "http://#{@app}.herokuapp.com deployed to Heroku", all_output
end

When /^I list all apps on Heroku$/ do
  sha = in_current_dir do
    `git rev-parse HEAD`.chomp
  end
  output = run_clean 'rake heroku:apps'
  assert_partial_output "test_app is shorthand for the Heroku app #{@app} located at:", output
  assert_partial_output "git@heroku.com:#{@app}.git", output
  assert_partial_output "@ #{sha} master", output
end

When /^I install an addon$/ do
  # Install the campfire addon.
  overwrite_file 'config/heroku.yml', <<END_CONFIG.strip_heredoc
    test_app:
      app: #{@app}
      addons:
        - heroku-postgresql:dev

END_CONFIG

  output = run_clean 'rake test_app heroku:addons'
  # The output should show the new one ...
  assert_partial_output "heroku-postgresql:dev", output
end

Then /^(?:heroku_san|issue \d+) (?:is green|has been fixed)$/ do
  run_clean "heroku apps:destroy #{@app} --confirm #{@app}"
end

def assert_app_is_running
  vladimir.match(%r{<code>marvin</code>}, 'droids').should be, "http://#{@app}.herokuapp.com/droids are not the droids I'm looking for"
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
  ENV['TRAVIS_RUBY_VERSION'] || '1.9.3'
end
