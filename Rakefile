require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

desc 'Default: run unit tests.'
task :default => :spec

desc "Run all specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = ["-c", "-f progress"]
end
