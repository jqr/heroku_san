require 'spec_helper'
require 'tmpdir'

describe HerokuSan do
  specify ".new with a missing config file" do
    heroku_san = HerokuSan.new("/u/should/never/get/here")
    heroku_san.app_settings.should == {}
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
        expect { heroku_san.each_app do |w,x,y,z| true; end }.to raise_error HerokuSan::NoApps
      end
      
      it "yields to a block with args" do
        heroku_san << 'production'
        block = double('block')
        block.should_receive(:action).with('production',
                                           'git@heroku.com:awesomeapp.git', 
                                            heroku_san.app_settings['production']['config'])
        heroku_san.each_app do |stage, repos, config|
          block.action(stage, repos, config)
        end
      end
    end
    
    describe "#[]" do
      it "returns a config section" do
        heroku_san['production'].should == heroku_san.app_settings['production']
      end
    end

    it "#migrate" do
      heroku_san.should_receive(:sh).with("heroku run:rake db:migrate --app awesomeapp-staging")
      heroku_san.should_receive(:sh).with("heroku restart --app awesomeapp-staging")
      heroku_san.migrate('staging')
    end
    
    describe "#maintenance" do      
      it ":on" do
        heroku_san.should_receive(:sh).with("heroku maintenance:on --app awesomeapp")
        heroku_san.maintenance('production', :on)
      end

      it ":off" do
        heroku_san.should_receive(:sh).with("heroku maintenance:off --app awesomeapp")
        heroku_san.maintenance('production', :off)
      end
      
      it ":busy raises an ArgumentError" do
        expect do
          heroku_san.maintenance('production', :busy) 
        end.to raise_error ArgumentError, "Action #{:busy.inspect} must be one of (:on, :off)"      
      end
    end
    
    context "celadon cedar stack has a different API" do
      describe "#stack" do
        it "returns the name of the stack from heroku" do
          heroku_san.should_receive("`").with("heroku stack --app awesomeapp") {
<<EOT
  aspen-mri-1.8.6
* bamboo-mri-1.9.2
  bamboo-ree-1.8.7
  cedar (beta)
EOT
          }
          heroku_san.stack('production').should == 'bamboo-mri-1.9.2'
        end
      
        it "returns the stack name from the config if it is set there" do
          heroku_san.should_not_receive("`")
          heroku_san.stack('staging').should == 'bamboo-ree-1.8.7'
        end
      end
          
      describe "#run" do
        it "runs commands using the pre-cedar format" do
          heroku_san.should_receive(:sh).with("heroku run:rake foo bar bleh --app awesomeapp-staging")
          heroku_san.run('staging', 'rake', 'foo bar bleh')
        end
        it "runs commands using the new cedar format" do
          heroku_san.should_receive(:sh).with("heroku run worker foo bar bleh --app awesomeapp-demo")
          heroku_san.run('demo', 'worker', 'foo bar bleh')
        end
      end
    end
    
    describe "#create" do
      it "creates an app on heroku" do
        heroku_san.should_receive(:sh).with("heroku apps:create awesomeapp")
        heroku_san.create('production')
      end
    end

    describe "#create_config" do
      it "creates a new file using the example file" do
        Dir.mktmpdir do |dir|
          tmp_config_file = File.join dir, 'config.yml'
          heroku_san = HerokuSan.new(tmp_config_file)
          FileUtils.should_receive(:cp).with(template_config_file, heroku_san.config_file)
          heroku_san.create_config.should be_true
        end
      end
      
      it "does not overwrite an existing file" do
        FileUtils.should_not_receive(:cp)
        heroku_san.create_config.should be_false
      end
    end
    
    describe "#sharing_add" do
      it "add collaborators" do
        heroku_san.should_receive(:sh).with("heroku sharing:add email@example.com --app awesomeapp")
        heroku_san.sharing_add('production', 'email@example.com')
      end
    end

    describe "#sharing_remove" do
      it "removes collaborators" do
        heroku_san.should_receive(:sh).with("heroku sharing:remove email@example.com --app awesomeapp")
        heroku_san.sharing_remove('production', 'email@example.com')
      end
    end
    
    describe "#long_config" do
      it "prints out the remote config" do
        heroku_san.should_receive(:sh).with("heroku config --long --app awesomeapp") {
<<EOT
BUNDLE_WITHOUT      => development:test
DATABASE_URL        => postgres://thnodhxrzn:T0-UwxLyFgXcnBSHmyhv@ec2-50-19-216-194.compute-1.amazonaws.com/thnodhxrzn
LANG                => en_US.UTF-8
RACK_ENV            => production
SHARED_DATABASE_URL => postgres://thnodhxrzn:T0-UwxLyFgXcnBSHmyhv@ec2-50-19-216-194.compute-1.amazonaws.com/thnodhxrzn
EOT
        }
        heroku_san.long_config('production')
      end
    end
    
    describe "#capture" do
      it "captures a bundle" do
        heroku_san.should_receive(:sh).with("heroku bundles:capture --app awesomeapp")
        heroku_san.capture('production')
      end
    end
    
    describe "#restart" do
      it "restarts an app" do
        heroku_san.should_receive(:sh).with("heroku restart --app awesomeapp")
        heroku_san.restart('production')
      end
    end
    
    describe "#logs" do
      it "returns log files" do
        heroku_san.should_receive(:sh).with("heroku logs --app awesomeapp")
        heroku_san.logs('production')
      end
    end
    
  end
end