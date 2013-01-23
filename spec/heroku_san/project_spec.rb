require 'spec_helper'
require 'tmpdir'

describe HerokuSan::Project do
  let(:heroku_config_file) { File.join(SPEC_ROOT, "fixtures", "example.yml") }
  let(:heroku_san) { HerokuSan::Project.new(heroku_config_file) }
  subject { heroku_san }

  describe ".new" do
    its(:all) { should =~ %w[production staging demo] }
    specify "with a missing config file has no stages" do
      heroku_san = HerokuSan::Project.new("/u/should/never/get/here")
      heroku_san.all.should == []
    end
  
    specify "with a deploy option configures each stage with the strategy" do
      heroku_san = HerokuSan::Project.new(heroku_config_file, :deploy => HerokuSan::Deploy::Base)
      heroku_san << heroku_san.all
      heroku_san.each_app do |stage|
        stage.instance_variable_get('@options')['deploy'].should == HerokuSan::Deploy::Base
      end
    end
  end
  
  describe "#apps constructs the deploy list" do
    it "appends known shorthands to apps" do
      heroku_san.apps.should == []
      heroku_san << 'production'
      heroku_san.apps.should == %w[production]
      heroku_san << 'staging'
      heroku_san.apps.should == %w[production staging]
      heroku_san << 'unknown'
      heroku_san.apps.should == %w[production staging]
    end
  
    it "appends .all (or any array)" do
      heroku_san << heroku_san.all
      heroku_san.apps.should == heroku_san.all
    end
  
    describe "extra (default) behaviors" do
      specify "on a git branch that matches an app name" do
        heroku_san.should_receive(:git_active_branch) { "staging" }
        $stdout.should_receive(:puts).with("Defaulting to 'staging' as it matches the current branch")
        expect {
          heroku_san.apps.should == %w[staging]
        }.to change{heroku_san.instance_variable_get('@apps')}.from([]).to(%w[staging])
      end
    
      specify "on a git branch that doesn't matches an app name" do
        heroku_san.should_receive(:git_active_branch) { "master" }
        heroku_san.apps.should == %w[]
      end
    
      context "with only a single configured app" do        
        let(:heroku_san) { HerokuSan::Project.new(File.join(SPEC_ROOT, "fixtures", "single_app.yml")) }
        it "returns the app" do
          $stdout.should_receive(:puts).with('Defaulting to "production" since only one app is defined')
          expect {
            heroku_san.apps.should == %w[production]
          }.to change{heroku_san.instance_variable_get('@apps')}.from([]).to(%w[production])
        end
      end
    end
  end
  
  describe "#each_app" do    
    it "raises an error is no apps were specified" do
      expect { heroku_san.each_app do true end }.to raise_error HerokuSan::NoApps
    end
    
    it "yields to a block with args" do
      heroku_san << 'production'
      block = double('block')
      block.should_receive(:action).with(heroku_san['production'])
      heroku_san.each_app do |stage|
        block.action(stage)
      end
    end
  end
  
  describe "#[]" do
    it "returns a config section" do
      heroku_san.all.each do |app|
        heroku_san[app].should be_a HerokuSan::Stage
      end
    end
  end
end