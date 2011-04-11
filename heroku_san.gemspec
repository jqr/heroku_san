# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{heroku_san}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Elijah Miller", "Glenn Roberts"]
  s.date = %q{2011-03-14}
  s.description = %q{Manage multiple Heroku instances/apps for a single Rails app using Rake}
  s.email = %q{elijah.miller@gmail.com}
  s.homepage = %q{http://github.com/glennr/heroku_san}
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.rubygems_version = %q{1.6.1}
  s.summary = %q{A bunch of useful Rake tasks for managing your Heroku apps}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, ['>= 2'])
      s.add_runtime_dependency(%q<heroku>)
      s.add_development_dependency(%q<rails>, ['>= 3'])
      s.add_development_dependency(%q<aruba>)
      s.add_development_dependency(%q<cucumber>)
    else
      s.add_dependency(%q<rails>, ['>= 2'])
      s.add_dependency(%q<heroku>)
      s.add_dependency(%q<aruba>)
      s.add_dependency(%q<cucumber>)
    end
  else
    s.add_dependency(%q<rails>, ['>= 2'])
    s.add_dependency(%q<heroku>)
    s.add_dependency(%q<aruba>)
    s.add_dependency(%q<cucumber>)
  end
end

