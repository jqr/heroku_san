require 'spec_helper'
require 'heroku_san/git'

class GitTest; include Git; end

describe GitTest do
  describe "#git_push" do    
    it "pushes to heroku" do
      subject.should_receive(:sh).with("git update-ref refs/heroku_san/deploy HEAD")
      subject.should_receive(:sh).with("git push git@heroku.com:awesomeapp.git  refs/heroku_san/deploy:refs/heads/master")
      subject.should_receive(:sh).with("git update-ref -d refs/heroku_san/deploy")
      subject.git_push(nil, 'git@heroku.com:awesomeapp.git')
    end
    
    it "pushes a specific commit to heroku" do
      subject.should_receive(:sh).with("git update-ref refs/heroku_san/deploy kommit")
      subject.should_receive(:sh).with("git push git@heroku.com:awesomeapp.git  refs/heroku_san/deploy:refs/heads/master")
      subject.should_receive(:sh).with("git update-ref -d refs/heroku_san/deploy")
      subject.git_push('kommit', 'git@heroku.com:awesomeapp.git')
    end
    
    it "includes options, too" do
      subject.should_receive(:sh).with("git update-ref refs/heroku_san/deploy HEAD")
      subject.should_receive(:sh).with("git push git@heroku.com:awesomeapp.git --force -v refs/heroku_san/deploy:refs/heads/master")
      subject.should_receive(:sh).with("git update-ref -d refs/heroku_san/deploy")
      subject.git_push(nil, 'git@heroku.com:awesomeapp.git', %w[--force -v])
    end
  end

  describe "#git_tag" do
    it "returns the latest tag that matches the pattern" do
      subject.should_receive("`").with("git tag -l 'pattern*'").and_return("x\n\y\n\z\n")
      subject.git_tag('pattern*').should == "z"
    end
    it "returns nil if no tags match the pattern" do
      subject.should_receive("`").with("git tag -l 'pattern*'").and_return("\n")
      subject.git_tag('pattern*').should == nil
    end
  end
end