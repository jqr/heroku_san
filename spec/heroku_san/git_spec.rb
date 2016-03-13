require 'spec_helper'
require 'heroku_san/git'

class GitTest; include HerokuSan::Git; end

describe GitTest do
  describe "#git_push" do    
    it "pushes to heroku" do
      expect(subject).to receive(:sh).with("git update-ref refs/heroku_san/deploy HEAD^{commit}")
      expect(subject).to receive(:sh).with("git push https://git.heroku.com/awesomeapp.git  refs/heroku_san/deploy:refs/heads/master")
      expect(subject).to receive(:sh).with("git update-ref -d refs/heroku_san/deploy")
      subject.git_push(nil, 'https://git.heroku.com/awesomeapp.git')
    end
    
    it "pushes a specific commit to heroku" do
      expect(subject).to receive(:sh).with("git update-ref refs/heroku_san/deploy kommit^{commit}")
      expect(subject).to receive(:sh).with("git push git@heroku.com:awesomeapp.git  refs/heroku_san/deploy:refs/heads/master")
      expect(subject).to receive(:sh).with("git update-ref -d refs/heroku_san/deploy")
      subject.git_push('kommit', 'git@heroku.com:awesomeapp.git')
    end
    
    it "includes options, too" do
      expect(subject).to receive(:sh).with("git update-ref refs/heroku_san/deploy HEAD^{commit}")
      expect(subject).to receive(:sh).with("git push git@heroku.com:awesomeapp.git --force -v refs/heroku_san/deploy:refs/heads/master")
      expect(subject).to receive(:sh).with("git update-ref -d refs/heroku_san/deploy")
      subject.git_push(nil, 'git@heroku.com:awesomeapp.git', %w[--force -v])
    end

    it "propagates any errors, but still cleans up" do
      expect(subject).to receive(:sh).with("git update-ref refs/heroku_san/deploy HEAD^{commit}")
      expect(subject).to receive(:sh).with("git push git@heroku.com:awesomeapp.git  refs/heroku_san/deploy:refs/heads/master").and_raise
      expect(subject).to receive(:sh).with("git update-ref -d refs/heroku_san/deploy")
      expect { subject.git_push(nil, 'git@heroku.com:awesomeapp.git') }.to raise_error StandardError
    end
  end

  describe "#git_tag" do
    it "returns the latest tag that matches the pattern" do
      expect(subject).to receive("`").with("git tag -l 'pattern*'") { "x\n\y\n\z\n" }
      expect(subject.git_tag('pattern*')).to eq "z"
    end

    it "raises exception if no tags match the pattern" do
      expect(subject).to receive("`").with("git tag -l 'pattern*'") { "\n" }
      expect {
        subject.git_tag('pattern*')
      }.to raise_error(HerokuSan::Git::NoTagFoundError)
    end

    it "returns nil for a nil glob" do
      expect(subject).not_to receive("`").with("git tag -l ''") { "\n" }
      expect(subject.git_tag(nil)).to be_nil
    end
  end
  
  describe "#git_rev_parse" do
    it "returns the rev based on the tag" do
      expect(subject).to receive("`").with("git rev-parse prod/1234567890") { "sha\n" }
      expect(subject.git_rev_parse('prod/1234567890')).to eq "sha"
    end

    it "returns nil for a blank tag" do
      expect(subject).not_to receive("`").with("git rev-parse ") { "\n" }
      expect(subject.git_rev_parse(nil)).to be_nil
    end
  end

  describe "#git_revision" do
    it "returns the current revision of the repository (on Heroku)" do
      expect(subject).to receive("`").with("git ls-remote --heads staging master") { "sha\n" }
      expect(subject.git_revision('staging')).to eq 'sha'
    end
    
    it "returns nil if there is no revision (i.e. not deployed yet)" do
      expect(subject).to receive("`").with("git ls-remote --heads staging master") { "\n" }
      expect(subject.git_revision('staging')).to be_nil
    end
  end
  
  describe "#git_named_rev" do
    it "returns symbolic names for given rev" do
      expect(subject).to receive("`").with("git name-rev sha") {"sha production/123456\n"}
      expect(subject.git_named_rev('sha')).to eq 'sha production/123456'
    end
  end
end