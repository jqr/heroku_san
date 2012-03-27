require 'spec_helper'
require 'heroku/client'

describe HerokuSan::Stage do
  include Git
  subject { HerokuSan::Stage.new('production', {"app" => "awesomeapp", "stack" => "bamboo-ree-1.8.7"})}

  before do
    @heroku_client = mock(Heroku::Client)
    Heroku::Auth.stub(:client).and_return(@heroku_client)
  end

  context "initializes" do
    subject { HerokuSan::Stage.new('production', 
      {"stack" => "cedar", 
       "app"   => "awesomeapp-demo", 
       "tag"   => "demo/*", 
       "config"=> {"BUNDLE_WITHOUT"=>"development:test"}
      })}

    its(:name)   { should == 'production' }
    its(:app)    { should == 'awesomeapp-demo' }
    its(:stack)  { should == 'cedar' }
    its(:tag)    { should == "demo/*" }
    its(:config) { should == {"BUNDLE_WITHOUT"=>"development:test"} }
    its(:repo)   { should == 'git@heroku.com:awesomeapp-demo.git' }
  end
  
  describe "#app" do
    its(:app) { should == 'awesomeapp'}
    context "blank app" do
      subject { HerokuSan::Stage.new('production') }
      it "should raise an error" do
        expect { subject.app }.to raise_error(HerokuSan::MissingApp, /production: is missing the app: configuration value\./)
      end
    end
  end
  
  describe "#stack" do
    it "returns the name of the stack from Heroku" do
      subject = HerokuSan::Stage.new('production', {"app" => "awesomeapp"})
      @heroku_client.should_receive(:list_stacks).with('awesomeapp').
        and_return { [{'name' => 'other'}, {'name' => 'the-one', 'current' => true}] }
      subject.stack.should == 'the-one'
    end
  
    it "returns the stack name from the config if it is set there" do
      subject = HerokuSan::Stage.new('production', {"app" => "awesomeapp", "stack" => "cedar"})
      subject.stack.should == 'cedar'
    end
  end

  describe "#run" do
    it "runs commands using the pre-cedar format" do
      subject.should_receive(:sh).with("heroku run:rake foo bar bleh --app awesomeapp")
      subject.run 'rake', 'foo bar bleh'
    end
    it "runs commands using the new cedar format" do
      subject = HerokuSan::Stage.new('production', {"app" => "awesomeapp", "stack" => "cedar"})
      subject.should_receive(:sh).with("heroku run worker foo bar bleh --app awesomeapp")
      subject.run 'worker', 'foo bar bleh'
    end
  end

  describe "#deploy" do
    it "deploys to heroku" do
      subject.should_receive(:git_push).with(git_parsed_tag(subject.tag), subject.repo, [])
      subject.deploy
    end
    
    it "deploys with a custom sha" do
      subject.should_receive(:git_push).with('deadbeef', subject.repo, [])
      subject.deploy('deadbeef')
    end
    
    it "deploys with --force" do
      subject.should_receive(:git_push).with(git_parsed_tag(subject.tag), subject.repo, %w[--force])
      subject.deploy(nil, :force)
    end
    
    it "deploys with a custom sha & --force" do
      subject.should_receive(:git_push).with('deadbeef', subject.repo, %w[--force])
      subject.deploy('deadbeef', :force)
    end
  end

  describe "#migrate" do
    it "runs rake db:migrate" do
      subject.should_receive(:rake).with('db:migrate').and_return 'output:'
      # @heroku_client.should_receive(:rake).with('awesomeapp', 'db:migrate').and_return "output:"
      @heroku_client.should_receive(:ps_restart).with('awesomeapp').and_return "restarted"
      subject.migrate.should == "restarted"
    end
  end
  
  describe "#maintenance" do
    it ":on" do
      @heroku_client.should_receive(:maintenance).with('awesomeapp', :on) {'on'}
      subject.maintenance(:on).should == 'on'
    end

    it ":off" do
      @heroku_client.should_receive(:maintenance).with('awesomeapp', :off) {'off'}
      subject.maintenance(:off).should == 'off'
    end
    
    it "otherwise raises an ArgumentError" do
      expect do
        subject.maintenance :busy
      end.to raise_error ArgumentError, "Action #{:busy.inspect} must be one of (:on, :off)"      
    end
    
    context "with a block" do
      it "wraps it in a maitenance mode" do
        @heroku_client.should_receive(:maintenance).with('awesomeapp', :on).ordered
        reactor = mock("Reactor"); reactor.should_receive(:scram).with(:now).ordered
        @heroku_client.should_receive(:maintenance).with('awesomeapp', :off).ordered
        subject.maintenance do reactor.scram(:now) end
      end
      it "ensures that maintenance mode is turned off" do
        @heroku_client.should_receive(:maintenance).with('awesomeapp', :on).ordered
        reactor = mock("Reactor"); reactor.should_receive(:scram).with(:now).and_raise(RuntimeError)
        @heroku_client.should_receive(:maintenance).with('awesomeapp', :off).ordered
        expect {
          subject.maintenance do reactor.scram(:now) end        
        }.to raise_error
      end
    end
  end

  describe "#create" do
    it "creates an app on heroku" do
      @heroku_client.should_receive(:create).with('awesomeapp', {:stack => 'bamboo-ree-1.8.7'})
      subject.create
    end
    it "uses the default stack if none is given" do
      subject = HerokuSan::Stage.new('production', {"app" => "awesomeapp"})
      @heroku_client.should_receive(:create).with('awesomeapp')
      subject.create
    end
    it "sends a nil app name if none is given (Heroku will generate one)" do
      subject = HerokuSan::Stage.new('production', {"app" => nil})
      @heroku_client.should_receive(:create).with(nil).and_return('warm-ocean-9218')
      subject.create.should == 'warm-ocean-9218'
    end
  end
  
  describe "#sharing_add" do
    it "add collaborators" do
      subject.should_receive(:sh).with("heroku sharing:add email@example.com --app awesomeapp")
      subject.sharing_add 'email@example.com'
    end
  end

  describe "#sharing_remove" do
    it "removes collaborators" do
      subject.should_receive(:sh).with("heroku sharing:remove email@example.com --app awesomeapp")
      subject.sharing_remove 'email@example.com'
    end
  end

  describe "#long_config" do
    it "returns the remote config" do
      @heroku_client.should_receive(:config_vars).with('awesomeapp') { {'A' => 'one', 'B' => 'two'} }
      subject.long_config.should == { 'A' => 'one', 'B' => 'two' }
    end
  end

  describe "#restart" do
    it "restarts an app" do
      @heroku_client.should_receive(:ps_restart).with('awesomeapp').and_return "restarted"
      subject.restart.should == 'restarted'
    end
  end
  
  describe "#logs" do
    it "returns log files" do
      subject.should_receive(:sh).with("heroku logs --app awesomeapp")
      subject.logs
    end
    it "tails log files" do
      subject.should_receive(:sh).with("heroku logs --tail --app awesomeapp")
      subject.logs(:tail)
    end
  end

  describe "#push_config" do
    it "updates the configuration settings on Heroku" do
      subject = HerokuSan::Stage.new('test', {"app" => "awesomeapp", "config" => {:FOO => 'bar', :DOG => 'emu'}}) 
      @heroku_client.should_receive(:add_config_vars).with('awesomeapp', {:FOO => 'bar', :DOG => 'emu'}).and_return("{}")
      subject.push_config
    end
    it "pushes the options hash" do
      @heroku_client.should_receive(:add_config_vars).with('awesomeapp', {:RACK_ENV => 'magic'}).and_return("{}")
      subject.push_config(:RACK_ENV => 'magic')
    end
  end

  describe "#revision" do
    it "returns the named remote revision for the stage" do
      subject.should_receive(:git_revision).with(subject.repo) {"sha"}
      subject.should_receive(:git_named_rev).with('sha') {"sha production/123456"}
      subject.revision.should == 'sha production/123456'
    end
    it "returns nil if the stage has never been deployed" do
      subject.should_receive(:git_revision).with(subject.repo) {nil}
      subject.should_receive(:git_named_rev).with(nil) {''}
      subject.revision.should == ''
    end
  end
end