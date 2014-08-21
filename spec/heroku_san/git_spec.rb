require 'spec_helper'
require 'heroku_san/git'

class GitTest; include HerokuSan::Git; end

describe GitTest do
  describe "#git_push" do
    it "pushes to heroku" do
      expect_successful_subprocess("git update-ref refs/heroku_san/deploy HEAD^{commit}")
      expect_successful_subprocess("git push git@heroku.com:awesomeapp.git  refs/heroku_san/deploy:refs/heads/master")
      expect_successful_subprocess("git update-ref -d refs/heroku_san/deploy")
      subject.git_push(nil, 'git@heroku.com:awesomeapp.git')
    end

    it "pushes a specific commit to heroku" do
      expect_successful_subprocess("git update-ref refs/heroku_san/deploy kommit^{commit}")
      expect_successful_subprocess("git push git@heroku.com:awesomeapp.git  refs/heroku_san/deploy:refs/heads/master")
      expect_successful_subprocess("git update-ref -d refs/heroku_san/deploy")
      subject.git_push('kommit', 'git@heroku.com:awesomeapp.git')
    end

    it "includes options, too" do
      expect_successful_subprocess("git update-ref refs/heroku_san/deploy HEAD^{commit}")
      expect_successful_subprocess("git push git@heroku.com:awesomeapp.git --force -v refs/heroku_san/deploy:refs/heads/master")
      expect_successful_subprocess("git update-ref -d refs/heroku_san/deploy")
      subject.git_push(nil, 'git@heroku.com:awesomeapp.git', %w[--force -v])
    end

    it "propagates any errors, but still cleans up" do
      expect_successful_subprocess("git update-ref refs/heroku_san/deploy HEAD^{commit}")
      expect_failed_subprocess("git push git@heroku.com:awesomeapp.git  refs/heroku_san/deploy:refs/heads/master")
      expect_successful_subprocess("git update-ref -d refs/heroku_san/deploy")
      expect { subject.git_push(nil, 'git@heroku.com:awesomeapp.git') }.to raise_error
    end
  end

  describe "#git_tag" do
    it "returns the latest tag that matches the pattern" do
      expect_successful_subprocess("git tag -l 'pattern*'", "x\n\y\n\z\n")
      subject.git_tag('pattern*').should == "z"
    end

    it "raises exception if no tags match the pattern" do
      expect_successful_subprocess("git tag -l 'pattern*'")
      expect {
        subject.git_tag('pattern*')
      }.to raise_error(HerokuSan::Git::NoTagFoundError)
    end

    it "returns nil for a nil glob" do
      Open3.should_not_receive(:capture3)
      subject.git_tag(nil).should == nil
    end

    it "raises an exception if the git process fails" do
      expect_failed_subprocess("git tag -l 'pattern*'")
      expect {
        subject.git_tag('pattern*')
      }.to raise_error(RuntimeError)
    end
  end

  describe "#git_rev_parse" do
    it "returns the rev based on the tag" do
      expect_successful_subprocess("git rev-parse prod/1234567890", "sha\n")
      subject.git_rev_parse('prod/1234567890').should == "sha"
    end

    it "returns nil for a blank tag" do
      Open3.should_not_receive(:capture3)
      subject.git_rev_parse(nil).should == nil
    end

    it "raises an exception if the git process fails" do
      expect_failed_subprocess("git rev-parse prod/1234567890")
      expect {
        subject.git_rev_parse('prod/1234567890')
      }.to raise_error(RuntimeError)
    end
  end

  describe "#git_revision" do
    it "returns the current revision of the repository (on Heroku)" do
      expect_successful_subprocess("git ls-remote --heads staging master", "sha\n")
      subject.git_revision('staging').should == 'sha'
    end

    it "returns nil if there is no revision (i.e. not deployed yet)" do
      expect_successful_subprocess("git ls-remote --heads staging master")
      subject.git_revision('staging').should == nil
    end

    it "raises an exception if the git process fails" do
      expect_failed_subprocess("git ls-remote --heads staging master")
      expect {
        subject.git_revision('staging')
      }.to raise_error(RuntimeError)
    end
  end

  describe "#git_named_rev" do
    it "returns symbolic names for given rev" do
      expect_successful_subprocess("git name-rev sha", "sha production/123456\n")
      subject.git_named_rev('sha').should == 'sha production/123456'
    end

    it "raises an exception if the git process fails" do
      expect_failed_subprocess("git name-rev sha", "sha production/123456\n")
      expect {
        subject.git_named_rev('sha')
      }.to raise_error(RuntimeError)
    end
  end

  def expect_successful_subprocess(command, stdout = "\n")
    process_status = double(success?: true)
    Open3.should_receive(:capture3).with(command) { [stdout, '', process_status] }
  end

  def expect_failed_subprocess(command, stderr = "\n")
    process_status = double(success?: false, exitstatus: 123)
    Open3.should_receive(:capture3).with(command) { ['', stderr, process_status] }
  end
end
