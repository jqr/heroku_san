World(Aruba::Api)

Given /^I have a new Rails project$/ do
  # template = File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'features', 'data', 'template.rb')
  cmd = "rails new heroku_san_test --quiet --force --database=postgresql --skip-bundle --skip-javascript --skip-test-unit --skip-sprockets" #" --template #{template}"
  run_simple unescape(cmd)
end

When /^I am in the project directory$/ do
    cd '/heroku_san_test'
end

When /^I add heroku_san to the Gemfile$/ do
  append_to_file 'Gemfile', <<EOT
group :development, :test do
  gem 'heroku_san', :path => '../../../.'
end
EOT
end

When /^I run bundle install$/ do
  use_clean_gemset 'heroku_san_test'
  run_simple 'bundle install --quiet'
  write_file '.rvmrc', "rvm use default@heroku_san_test\n"
end

Then /^rake reports that the heroku: tasks are available$/ do
  run_simple 'rake -T heroku:'
  assert_partial_output 'rake heroku:apps', all_output
end

When /^I create a new config\/heroku\.yml file$/ do
  run_simple 'rake heroku:create_config'
  assert_matching_output %q{Copied example config to ".*.config.heroku.yml"}, all_output
  assert_matching_output %q{Please edit ".*.config.heroku.yml" with your application's settings.}, all_output
  overwrite_file 'config/heroku.yml', <<EOT
---
test_app:
EOT
end

When /^I create my project on Heroku$/ do
  cmd = 'rake test_app heroku:create'
  run_simple unescape(cmd)
  assert_matching_output %q{test_app: Created ([\w-]+)}, all_output
  output = stdout_from cmd
  @app = output.match(/test_app: Created ([\w-]+)/)[1]
  overwrite_file 'config/heroku.yml', <<EOT
---
test_app:
  app: #{@app}
EOT
end

When /^I list the remote configuration$/ do
  cmd = 'rake test_app heroku:config:list'
  run_simple unescape(cmd)
  assert_partial_output "APP_NAME: #{@app}", all_output
  assert_partial_output "URL: #{@app}.heroku.com", all_output
  output = stdout_from cmd
  @url = output.match(/\bURL:\s+(.*.heroku.com)\b/)[1]
  @curl = unescape("curl --silent http://#{@url}")
end

When /^I curl the app home page$/ do
  run_simple @curl
  output = stdout_from @curl
  assert_partial_output '<h1><strong>Heroku | Welcome to your new app!</strong></h1>', output
end

When /^I configure my project$/ do
  overwrite_file 'config/heroku.yml', <<EOT
---
test_app:
  app: #{@app}
  config:
    DROIDS: marvin
EOT
  cmd = 'rake test_app heroku:config'
  run_simple unescape(cmd)
  assert_partial_output 'DROIDS: marvin', all_output
end

When /^I turn maintenance on$/ do
  run_simple 'rake test_app heroku:maintenance_on'
  assert_partial_output 'test_app: Maintenance mode enabled.', all_output
  run_simple @curl
  output = stdout_from @curl
  assert_partial_output '<title>Offline for Maintenance</title>', all_output
end

When /^I turn maintenance off$/ do
  run_simple 'rake test_app heroku:maintenance_off'
  assert_partial_output 'test_app: Maintenance mode disabled.', all_output
  run_simple @curl + "/droids"
  assert_partial_output %Q{<code>marvin</code>}, all_output
end

When /^I restart my project$/ do
  run_simple 'rake test_app heroku:restart'
  assert_partial_output 'test_app: Restarted.', all_output
end

When /^I deploy my project$/ do
  run_simple 'git init .'
  run_simple 'rails generate scaffold droids'
  append_to_file 'app/views/droids/index.html.erb', %Q{\n<div><code><%= ENV['DROIDS'] -%></code></div>\n}
  run_simple 'git add .'
  run_simple 'git commit -m "Initial commit"'
  run_simple 'rake test_app deploy'
  assert_partial_output "http://#{@app}.heroku.com deployed to Heroku", all_output
end

When /^I list all apps on Heroku$/ do
  run_simple 'rake heroku:apps'
  assert_partial_output "test_app is shorthand for the Heroku app #{@app} located at:", all_output
  assert_partial_output "git@heroku.com:#{@app}.git", all_output
  assert_matching_output '@ \w{40} master', all_output
end

Then /^heroku_san is green$/ do
  run_simple "heroku apps:destroy #{@app} --confirm #{@app}"
end
