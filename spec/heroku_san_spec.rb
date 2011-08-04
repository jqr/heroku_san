require 'spec_helper'
require 'tmpdir'

describe HerokuSan do
  specify ".new with a missing config file" do
    heroku_san = HerokuSan.new("/u/should/never/get/here")
    heroku_san.all.should == []
  end
  
  context "using the example config file" do
    let(:heroku_config_file) { File.join(SPEC_ROOT, "fixtures", "example.yml") }
    let(:template_config_file) { 
      path = File.join(SPEC_ROOT, "..", "lib/templates", "heroku.example.yml")
      (File.respond_to? :realpath) ? File.realpath(path) : path
    }
    let(:heroku_san) { HerokuSan.new(heroku_config_file) }
    
    it "#all" do
      heroku_san.all.should =~ %w[production staging demo]
    end
    
    context "using the heroku_san format" do
      let(:heroku_san) { HerokuSan.new(File.join(SPEC_ROOT, "fixtures", "old_format.yml")) }

      it "returns a list of apps" do
        heroku_san.all.should =~ %w[production staging demo]
      end
    end
        
    describe "Adding an app to the deploy list" do
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
    end
    
    describe "#apps extra default behaviors" do
      specify "on a git branch that matches an app name" do
        heroku_san.should_receive(:git_active_branch) { "staging" }
        $stdout.should_receive(:puts).with("Defaulting to 'staging' as it matches the current branch")
        heroku_san.apps.should == %w[staging]
      end
      
      specify "on a git branch that doesn't matches an app name" do
        heroku_san.should_receive(:git_active_branch) { "master" }
        heroku_san.apps.should == %w[]
      end
      
      context "but only a single configured app" do        
        let(:heroku_san) { HerokuSan.new(File.join(SPEC_ROOT, "fixtures", "single_app.yml")) }
        it "returns the app" do
          $stdout.should_receive(:puts).with('Defaulting to "production" since only one app is defined')
          heroku_san.apps.should == %w[production]
        end
      end
    end
    
    describe "#each_app" do    
      it "raises an error is no apps were specified" do
        expect { heroku_san.each_app do true; end }.to raise_error HerokuSan::NoApps
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

    describe "#create_config" do
      it "creates a new file using the example file" do
        Dir.mktmpdir do |dir|
          tmp_config_file = File.join dir, 'config.yml'
          heroku_san = HerokuSan.new(tmp_config_file)
          FileUtils.should_receive(:cp).with(template_config_file, tmp_config_file)
          heroku_san.create_config.should be_true
        end
      end
      
      it "does not overwrite an existing file" do
        FileUtils.should_not_receive(:cp)
        heroku_san.create_config.should be_false
      end
    end    
  end
end