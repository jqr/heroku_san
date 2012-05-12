World(Aruba::Api)
require 'active_support/core_ext/string/strip'

Given /^I have a new Rails project$/ do
  cmd = "rails new test_app --quiet --force --database=postgresql --skip-bundle --skip-javascript --skip-test-unit --skip-sprockets"
  run_simple unescape(cmd)
end

Given /^I have a new Sinatra project$/ do
  create_dir 'test_app/config'
  write_file 'test_app/app.rb', <<EOT.strip_heredoc
    require 'sinatra'

    get '/' do
      'Hello, world.'
    end
EOT

  write_file 'test_app/config.ru', <<EOT.strip_heredoc
    require './app'
    run Sinatra::Application
EOT

  write_file 'test_app/Gemfile', <<EOT.strip_heredoc
    source 'http://rubygems.org'
    gem 'sinatra'
EOT

  write_file 'test_app/Rakefile', <<EOT.strip_heredoc
    require "bundler/setup"
    require "heroku_san"
    config_file = File.join(File.expand_path(File.dirname(__FILE__)), 'config', 'heroku.yml')
    HerokuSan.project = HerokuSan::Project.new(config_file, :deploy => HerokuSan::Deploy::Sinatra)
    load "heroku_san/tasks.rb"
EOT

end

When /^I am in the project directory$/ do
  cd '/test_app'
  run_simple 'git init .'
end

When /^I commit any changes with "(.*)"$/ do |message|
  run_simple 'git add .'
  run_simple "git commit -m '#{message}'"
end

When /^I add heroku_san to the Gemfile$/ do
  append_to_file 'Gemfile', <<EOT.strip_heredoc
    group :development, :test do
      gem 'heroku_san', :path => '../../../.'
    end
EOT

end

When /^I run bundle install$/ do
  use_clean_gemset 'heroku_san_test'
  run_simple 'bundle install --quiet'
end

Then /^rake reports that the heroku: tasks are available$/ do
  run_simple 'bundle exec rake -T heroku:'
  output = stdout_from 'bundle exec rake -T heroku:'
  assert_partial_output 'rake heroku:apps', output
end

When /^I generate a new config file$/ do
  run_simple 'bundle exec rails generate heroku_san'
  output = stdout_from 'bundle exec rails generate heroku_san'
  assert_partial_output 'create  config/heroku.yml', output
  overwrite_simple_config_file
end

When /^I create a new config\/heroku\.yml file$/ do
  run_simple 'bundle exec rake heroku:create_config'
  output = stdout_from 'bundle exec rake heroku:create_config'
  assert_matching_output %q{Copied example config to ".*.config.heroku.yml"}, output
  assert_matching_output %q{Please edit ".*.config.heroku.yml" with your application's settings.}, output
  overwrite_simple_config_file
end

When /^I create my project on Heroku$/ do
  cmd = 'bundle exec rake test_app heroku:create'
  run_simple unescape(cmd)
  output = stdout_from cmd
  assert_matching_output %q{test_app: Created ([\w-]+)}, output
  
  @app = output.match(/test_app: Created ([\w-]+)/)[1]
  overwrite_file 'config/heroku.yml', <<EOT.strip_heredoc
    ---
    test_app:
      app: #{@app}
EOT
end

When /^I list the remote configuration$/ do
  cmd = 'bundle exec rake test_app heroku:config:list'
  run_simple unescape(cmd)
  output = stdout_from cmd
  assert_partial_output "APP_NAME: #{@app}", output
  assert_partial_output "URL: #{@app}.heroku.com", output
  
  @url = output.match(/\bURL:\s+(.*.heroku.com)\b/)[1]
  @curl = unescape("curl --silent http://#{@url}")
end

When /^I curl the app home page$/ do
  run_simple @curl
  output = stdout_from @curl
  assert_partial_output '<h1><strong>Heroku | Welcome to your new app!</strong></h1>', output
end

When /^I configure my project$/ do
  overwrite_file 'config/heroku.yml', <<EOT.strip_heredoc
    ---
    test_app:
      app: #{@app}
      config:
        DROIDS: marvin
EOT
  cmd = 'bundle exec rake test_app heroku:config'
  run_simple cmd
  output = stdout_from cmd
  assert_partial_output 'DROIDS: marvin', output
end

When /^I turn maintenance on$/ do
  run_simple 'bundle exec rake test_app heroku:maintenance_on'
  output = stdout_from 'bundle exec rake test_app heroku:maintenance_on'
  assert_partial_output 'test_app: Maintenance mode enabled.', output
  
  run_simple @curl
  output = stdout_from @curl
  assert_partial_output '<title>Offline for Maintenance</title>', output
end

When /^I turn maintenance off$/ do
  run_simple 'bundle exec rake test_app heroku:maintenance_off'
  output = stdout_from 'bundle exec rake test_app heroku:maintenance_off'
  assert_partial_output 'test_app: Maintenance mode disabled.', output
  assert_app_is_running
end

When /^I restart my project$/ do
  run_simple 'bundle exec rake test_app heroku:restart'
  output = stdout_from 'bundle exec rake test_app heroku:restart'
  assert_partial_output 'test_app: Restarted.', output
  assert_app_is_running
end

When /^I generate a scaffold$/ do
  run_simple 'bundle exec rails generate scaffold droid'
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
  run_simple 'bundle exec rake test_app deploy'
  assert_partial_output "http://#{@app}.heroku.com deployed to Heroku", all_output
end

When /^I list all apps on Heroku$/ do
  sha = in_current_dir do
    `git rev-parse HEAD`.chomp
  end
  run_simple 'bundle exec rake heroku:apps'
  output = stdout_from 'bundle exec rake heroku:apps'
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
        - deployhooks:campfire
END_CONFIG

  run_simple 'bundle exec rake test_app heroku:addons'
  output = stdout_from 'bundle exec rake test_app heroku:addons'
  # The output should show the default addons...
  assert_partial_output "shared-database:5mb", output
  # ... and the new one ...
  assert_partial_output "deployhooks:campfire", output
  # ... with a note about needing to configure it.
  assert_partial_output "https://api.heroku.com/myapps/#{@app}/addons/deployhooks:campfire", output
end

Then /^heroku_san is green$/ do
  run_simple "bundle exec heroku apps:destroy #{@app} --confirm #{@app}"
end

def assert_app_is_running
  run_simple @curl + "/droids"
  output = stdout_from @curl + "/droids"
  assert_partial_output %Q{<code>marvin</code>}, output
end

def overwrite_simple_config_file
  overwrite_file 'config/heroku.yml', <<EOT.strip_heredoc
    ---
    test_app:
EOT

end