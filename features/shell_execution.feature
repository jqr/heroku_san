@slow_process @announce-command
Feature: heroku_san can shell out to heroku without errors

  Scenario: Bundling a new project
    Given a directory named "ruby2test"
    And I cd to "ruby2test"
    And I write to "Gemfile" with:
    """
      source "https://rubygems.org"
      gem 'heroku_san', :path => '../../../.'
    """
    And I run `gem install bundler`
    And I run `bundle install`
    And the executable named "get_heroku_version.rb" with:
    """
      #!/usr/bin/env ruby
      require 'heroku_san'
      api = HerokuSan::API.new
      api.sh(nil, 'status')
    """
    And I run `bundle exec ruby ./get_heroku_version.rb`
    Then the output should contain "heroku-toolbelt"
    Then the output should contain "Production"
    Then the output should contain "Development"

