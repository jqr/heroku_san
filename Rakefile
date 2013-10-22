#!/usr/bin/env rake
require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'cucumber'
require 'cucumber/rake/task'

desc 'Default: run unit tests.'
task :default => :spec

desc "Run all specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

namespace 'cucumber' do
  Cucumber::Rake::Task.new(:remote) do |t|
    t.profile = "remote"
  end

  Cucumber::Rake::Task.new(:default) do |t|
    t.profile = "default"
  end
end

desc "Run travis test suite"
task :travis => [:spec, 'cucumber:default', 'cucumber:remote']

# for app in `heroku apps | tail +2`; do heroku apps:destroy --app $app --confirm $app; done
