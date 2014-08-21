require 'rake'
require 'rake/dsl_definition'
require 'open3'

module HerokuSan
  module Git
    class NoTagFoundError < Exception; end

    include Rake::DSL

    def git_clone(repos, dir)
      run_subprocess("git clone #{repos} #{dir}")
    end

    def git_active_branch
      run_subprocess("git branch").split("\n").select { |b| b =~ /^\*/ }.first.split(" ").last.strip
    end

    def git_push(commit, repo, options = [])
      commit ||= "HEAD"
      options ||= []
      begin
        run_subprocess("git update-ref refs/heroku_san/deploy #{commit}^{commit}")
        run_subprocess("git push #{repo} #{options.join(' ')} refs/heroku_san/deploy:refs/heads/master")
      ensure
        run_subprocess("git update-ref -d refs/heroku_san/deploy")
      end
    end

    def git_parsed_tag(tag)
      git_rev_parse(git_tag(tag))
    end

    def git_rev_parse(ref)
      return nil if ref.nil?
      run_subprocess("git rev-parse #{ref}").split("\n").first
    end

    def git_tag(glob)
      return nil if glob.nil?
      run_subprocess("git tag -l '#{glob}'").split("\n").last || (raise NoTagFoundError, "No tag found [#{glob}]")
    end

    def git_revision(repo)
      run_subprocess("git ls-remote --heads #{repo} master").split.first
    end

    def git_named_rev(ref)
      run_subprocess("git name-rev #{ref}").chomp
    end

    private

    def run_subprocess(command)
      output, error, status = Open3.capture3(command)
      if status.success?
        output
      else
        raise "Command '#{command}' failed with status #{status.exitstatus}: #{error}"
      end
    end
  end
end
