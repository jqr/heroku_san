require 'spec_helper'

describe HerokuSan do
  specify ".new with a missing config file" do
    heroku_san = HerokuSan.new("/u/should/never/get/here")
    heroku_san.app_settings.should == {}
    heroku_san.apps.should == []
  end
  
  context "using the old format" do
    let(:heroku_san) { HerokuSan.new(File.join(SPEC_ROOT, "fixtures", "old_format.yml")) }

    it "returns a list of apps" do
      heroku_san.apps.should =~ %w[production staging demo]
    end
  end
  
  context "using the example config file" do
    let(:heroku_san) { HerokuSan.new(File.join(SPEC_ROOT, "../lib/templates", "heroku.example.yml")) }
    
    it "returns a list of apps" do
      heroku_san.apps.should =~ %w[production staging demo]
    end
    
    specify "each app has a 'config' section" do
      heroku_san.apps.each do |app|
        heroku_san.app_settings[app]['config'].should be_a Hash
      end
    end
  end
  
end