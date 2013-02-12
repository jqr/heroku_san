require 'rake'
require 'rake/dsl_definition'

module HerokuSan
  module Git
    class NoTagFoundError < Exception; end

    include Rake::DSL

    def git_clone(repos, dir)
      sh "git clone #{repos} #{dir}"
    end

    def git_active_branch
      %x{git branch}.split("\n").select { |b| b =~ /^\*/ }.first.split(" ").last.strip
    end

    def git_push(commit, repo, options = [])
      commit ||= "HEAD"
      options ||= []
      begin
        sh "git update-ref refs/heroku_san/deploy #{commit}^{commit}"
        sh "git push #{repo} #{options.join(' ')} refs/heroku_san/deploy:refs/heads/master"
      ensure
        sh "git update-ref -d refs/heroku_san/deploy"
      end
    end

    def git_parsed_tag(tag)
      git_rev_parse(git_tag(tag))
    end

    def git_rev_parse(ref)
      return nil if ref.nil?
      %x{git rev-parse #{ref}}.split("\n").first
    end

    def git_tag(glob)
      return nil if glob.nil?
      %x{git tag -l '#{glob}'}.split("\n").last || (raise NoTagFoundError, "No tag found [#{glob}]")
    end

    def git_revision(repo)
      %x{git ls-remote --heads #{repo} master}.split.first
    end

    def git_named_rev(ref)
      %x{git name-rev #{ref}}.chomp
    end
  end
end