@slow_process @announce-cmd
Feature: heroku_san can shell out to heroku without errors

  Scenario: Bundling a ruby 2.0 project
    Given I run `mkdir -p ruby2test`
    And I cd to "ruby2test"
    And I write to "Gemfile" with:
    """
      source "https://rubygems.org"
      ruby '2.0.0'
      gem 'heroku_san', :path => '../../../.'
    """

    And I write to "get_heroku_version.rb" with:
    """
      #!/usr/bin/env ruby

      puts ENV['RUBY_VERSION']

      ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)

      require 'bundler/setup'

      require 'heroku_san'

      api = HerokuSan::API.new

      api.sh('any_app_name', 'auth:whoami')
    """
    And I write to "run_in_ruby_2.sh" with:
    """
    #!/usr/bin/env bash

    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

    rvm use 2.0.0
    bundle install

    ruby get_heroku_version.rb
    """
    And I run `chmod +x run_in_ruby_2.sh`
    And I cleanly run `./run_in_ruby_2.sh`
    Then the output should contain "heroku-toolbelt"
    # Fail if we see "Your Ruby version is 1.9.3, but your Gemfile specified 2.0.0"
    Then the output should not contain "Your Ruby version"
    Then the output should not contain "your Gemfile specified"

