require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "heroku_san"
    gem.summary = %Q{A bunch of useful Rake tasks for managing your Heroku apps}
    gem.description = %Q{Manage multiple Heroku instances/apps for a single Rails app using Rake}
    gem.email = "glenn.roberts@siyelo.com"
    gem.homepage = "http://github.com/glennr/heroku_san"
    gem.authors = ["Elijah Miller", "Glenn Roberts"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

desc 'Default: build gem.'
task :default => :build