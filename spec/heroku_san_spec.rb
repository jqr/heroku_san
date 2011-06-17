require 'spec_helper'

describe HerokuSan do
  specify ".new with a missing config file" do
    heroku_san = HerokuSan.new("/u/should/never/get/here")
    heroku_san.app_settings.should == {}
    heroku_san.all.should == []
  end
  
  context "using the example config file" do
    let(:heroku_san) { HerokuSan.new(File.join(SPEC_ROOT, "../lib/templates", "heroku.example.yml")) }
    
    it "#all" do
      heroku_san.all.should =~ %w[production staging demo]
    end
    
    context "using the heroku_san format" do
      let(:heroku_san) { HerokuSan.new(File.join(SPEC_ROOT, "fixtures", "old_format.yml")) }

      it "returns a list of apps" do
        heroku_san.all.should =~ %w[production staging demo]
      end
    end
    
    specify "each app has a 'config' section" do
      heroku_san.all.each do |app|
        heroku_san.app_settings[app]['config'].should be_a Hash
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
        heroku_san.should_receive(:active_branch).and_return("staging")
        $stdout.should_receive(:puts).with('Defaulting to "staging" as it matches the current branch')
        heroku_san.apps.should == %w[staging]
      end
      
      specify "on a git branch that doesn't matches an app name" do
        heroku_san.should_receive(:active_branch).and_return("master")
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
        expect { heroku_san.each_app do |w,x,y,z| true; end }.to raise_error HerokuSan::NoApps
      end
      
      it "yields to a block with four args" do
        heroku_san << 'production'
        block = double('block')
        block.should_receive(:action).with('production',
                                           'awesomeapp', 
                                           'git@heroku.com:awesomeapp.git', 
                                            heroku_san.app_settings['production']['config'])
        heroku_san.each_app do |name, app, repos, config|
          block.action(name, app, repos, config)
        end
      end
      
    end
  end
  
  
end