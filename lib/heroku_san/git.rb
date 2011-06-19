require 'rake'

module Git
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
      sh "git update-ref refs/heroku_san/deploy #{commit}"
      sh "git push #{repo} #{options.join(' ')} refs/heroku_san/deploy:refs/heads/master"
    ensure
      sh "git update-ref -d refs/heroku_san/deploy"
    end
  end
  
  def git_tag(tag)
    %x{git tag -l '#{tag}'}.split("\n").last
  end
end