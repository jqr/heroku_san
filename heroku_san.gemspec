# -*- encoding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'lib/heroku_san/version')

Gem::Specification.new do |s|
  s.name = %q{heroku_san}
  s.version = HerokuSan::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.authors = ["Elijah Miller", "Glenn Roberts", "Ryan Ahearn", "Ken Mayer"]
  s.description = %q{Manage multiple Heroku instances/apps for a single Rails app using Rake}
  s.email = %q{elijah.miller@gmail.com}
  s.homepage = %q{http://github.com/fastestforward/heroku_san}
  s.license = "MIT"
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["README.md"]
  s.rubygems_version = %q{1.6.1}
  s.summary = %q{
  A bunch of useful Rake tasks for managing your Heroku apps.
  NOTE: The Heroku Toolbelt must be installed to use this gem.
  https://toolbelt.heroku.com/
  }

  s.add_runtime_dependency("heroku-api", [">= 0.1.2"])
  s.add_runtime_dependency("json")
  s.add_runtime_dependency("rake")
end

