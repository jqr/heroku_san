require 'spec_helper'

module HerokuSan
  STOCK_CONFIG = {"BUNDLE_WITHOUT"=>"development:test", "LANG"=>"en_US.UTF-8", "RACK_ENV"=>"production"}

describe HerokuSan::Stage do
  include HerokuSan::Git
  subject { Factory::Stage.build('production', {"deploy" => HerokuSan::Deploy::Rails, "app" => "awesomeapp", "stack" => "cedar"})}
  before do
    HerokuSan::API.any_instance.stub(:preflight_check_for_cli)
  end

  context "initializes" do
    subject { Factory::Stage.build('production',
      {"stack" => "cedar", 
       "app"   => "awesomeapp-demo", 
       "tag"   => "demo/*", 
       "config"=> {"BUNDLE_WITHOUT"=>"development:test"},
       "addons"=> ['one:addon', 'two:addons']
      })}

    its(:name)   { should == 'production' }
    its(:app)    { should == 'awesomeapp-demo' }
    its(:stack)  { should == 'cedar' }
    its(:tag)    { should == "demo/*" }
    its(:config) { should == {"BUNDLE_WITHOUT"=>"development:test"} }
    its(:repo)   { should == 'git@heroku.com:awesomeapp-demo.git' }
    its(:addons) { should == ['one:addon', 'two:addons'] }
  end
  
  describe "#app" do
    its(:app) { should == 'awesomeapp'}
    context "blank app" do
      subject { Factory::Stage.build('production') }
      it "should raise an error" do
        expect { subject.app }.to raise_error(HerokuSan::MissingApp, /production: is missing the app: configuration value\./)
      end
    end
  end
  
  describe "#stack" do
    it "returns the name of the stack from Heroku" do
      subject = Factory::Stage.build('production', {"app" => "awesomeapp"})
      with_app(subject, 'name' => subject.app) do |app_data|
        subject.stack.should == 'bamboo-mri-1.9.2'
      end
    end
  
    it "returns the stack name from the config when it is set there" do
      subject = Factory::Stage.build('production', {"app" => "awesomeapp", "stack" => "cedar"})
      subject.stack.should == 'cedar'
    end
  end

  describe '#addons' do
    subject { Factory::Stage.build('production', {'addons' => addons}) }
    context 'default' do
      let(:addons) { nil }
      its(:addons) { should == [] }
    end
    context 'nested' do
      # This is for when you do:
      # default_addons: &default_addons
      #   - a
      #   - b
      # env:
      #   addons:
      #   - *default_addons
      #   - other
      let(:addons) { [ ['a', 'b'], 'other' ] }
      its(:addons) { should == [ 'a', 'b', 'other' ] }
    end
  end

  describe "#run" do
    it "runs commands using the new cedar format" do
      subject.heroku.should_receive(:system).with("heroku", "run", "worker foo bar bleh", "--app", "awesomeapp") { true }
      subject.run 'worker foo bar bleh'
    end
  end

  describe "#push" do
    it "deploys to heroku" do
      subject.should_receive(:git_parsed_tag).with(nil) {'tag'}
      subject.should_receive(:git_push).with('tag', subject.repo, [])
      subject.push
    end
    
    it "deploys with a custom sha" do
      subject.should_receive(:git_push).with('deadbeef', subject.repo, [])
      subject.push('deadbeef')
    end
    
    it "deploys with --force" do
      subject.should_receive(:git_parsed_tag).with(nil) {'tag'}
      subject.should_receive(:git_push).with('tag', subject.repo, %w[--force])
      subject.push(nil, :force)
    end
    
    it "deploys with a custom sha & --force" do
      subject.should_receive(:git_push).with('deadbeef', subject.repo, %w[--force])
      subject.push('deadbeef', :force)
    end
  end

  describe "#migrate" do
    it "runs rake db:migrate" do
      with_app(subject, 'name' => subject.app) do |app_data|
        subject.should_receive(:run).with('rake db:migrate').and_return 'output:'
        subject.migrate.should == "restarted"
      end
    end
  end
  
  describe "#deploy" do
    context "using the default strategy" do
      it "(rails) pushes & migrates" do
        HerokuSan::Deploy::Rails.any_instance.should_receive(:deploy)
        subject.deploy
      end
    end

    context "using a custom strategy" do
      class TestDeployStrategy < HerokuSan::Deploy::Base
        def deploy; end
      end
      subject = Factory::Stage.build('test', {"app" => "awesomeapp", "deploy" => TestDeployStrategy})
      it "(custom) calls deploy" do
        TestDeployStrategy.any_instance.should_receive(:deploy)
        subject.deploy
      end
    end
  end
  
  describe "#maintenance" do
    it ":on" do
      with_app(subject, 'name' => subject.app )do |app_data|
        subject.maintenance(:on).status.should == 200
      end
    end

    it ":off" do
      with_app(subject, 'name' => subject.app) do |app_data|
        subject.maintenance(:off).status.should.should == 200
      end
    end
    
    it "otherwise raises an ArgumentError" do
      expect do
        subject.maintenance :busy
      end.to raise_error ArgumentError, "Action #{:busy.inspect} must be one of (:on, :off)"      
    end
    
    context "with a block" do
      it "wraps it in a maintenance mode" do
        with_app(subject, 'name' => subject.app) do |app_data|
          subject.heroku.should_receive(:post_app_maintenance).with(subject.app, '1').ordered
          reactor = double("Reactor"); reactor.should_receive(:scram).with(:now).ordered
          subject.heroku.should_receive(:post_app_maintenance).with(subject.app, '0').ordered
          
          subject.maintenance {reactor.scram(:now)} 
        end
      end

      it "ensures that maintenance mode is turned off" do
        with_app(subject, 'name' => subject.app) do |app_data|
          subject.heroku.should_receive(:post_app_maintenance).with(subject.app, '1').ordered
          reactor = double("Reactor"); reactor.should_receive(:scram).and_raise(RuntimeError)
          subject.heroku.should_receive(:post_app_maintenance).with(subject.app, '0').ordered
          
          expect do subject.maintenance {reactor.scram(:now)} end.to raise_error
        end
      end
    end
  end

  describe "#create" do
    after do
      subject.heroku.delete_app(@app)
    end

    it "uses the provided name" do
      (@app = subject.create).should == 'awesomeapp'
    end

    it "creates an app on heroku" do
      subject = Factory::Stage.build('production')
      (@app = subject.create).should =~ /generated-name-\d+/
    end

    it "uses the default stack if none is given" do
      subject = Factory::Stage.build('production')
      (@app = subject.create).should =~ /generated-name-\d+/
      subject.heroku.get_stack(@app).body.detect{|stack| stack['current']}['name'].should == 'bamboo-mri-1.9.2'
    end

    it "uses the stack from the config" do
      (@app = subject.create).should == 'awesomeapp'
      subject.heroku.get_stack(@app).body.detect{|stack| stack['current']}['name'].should == 'cedar'
    end
  end
  
  describe "#long_config" do
    it "returns the remote config" do
      with_app(subject, 'name' => subject.app) do |app_data|
        subject.long_config.should == STOCK_CONFIG
      end
    end
  end

  describe "#push_config" do
    it "updates the configuration settings on Heroku" do
      subject = Factory::Stage.build('test', {"app" => "awesomeapp", "config" => {'FOO' => 'bar', 'DOG' => 'emu'}})
      with_app(subject, 'name' => subject.app) do |app_data|
        subject.push_config.should == STOCK_CONFIG.merge('FOO' => 'bar', 'DOG' => 'emu')
      end
    end

    it "pushes the options hash" do
      subject = Factory::Stage.build('test', {"app" => "awesomeapp", "config" => {'FOO' => 'bar', 'DOG' => 'emu'}})
      with_app(subject, 'name' => subject.app) do |app_data|
        subject.push_config('RACK_ENV' => 'magic').should == STOCK_CONFIG.merge('RACK_ENV' => 'magic')
      end
    end
  end

  describe "#restart" do
    it "restarts an app" do
      with_app(subject, 'name' => subject.app) do |app_data|
        subject.restart.should == 'restarted'
      end
    end
  end
  
  describe "#logs" do
    it "returns log files" do
      subject.heroku.should_receive(:system).with("heroku", "logs", "--app", "awesomeapp") { true }
      subject.logs
    end

    it "tails log files" do
      subject.heroku.should_receive(:system).with("heroku", "logs", "--tail", "--app", "awesomeapp") { true }
      subject.logs(:tail)
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
  
  describe "#installed_addons" do
    it "returns the list of installed addons" do
      with_app(subject, 'name' => subject.app) do |app_data|
        subject.installed_addons.map{|a|a['name']}.should include *%w[shared-database:5mb]
      end
    end
  end

  describe '#install_addons' do
    subject { Factory::Stage.build('production', {"app" => "awesomeapp", "stack" => "bamboo-ree-1.8.7", "addons" => %w[custom_domains:basic ssl:piggyback]})}

    it "installs the addons" do
      with_app(subject, 'name' => subject.app) do |app_data| 
        subject.install_addons.map{|a| a['name']}.should include *%w[custom_domains:basic ssl:piggyback]
        subject.installed_addons.map{|a|a['name']}.should =~ subject.install_addons.map{|a| a['name']}
      end
    end

    it "only installs missing addons" do
      subject = Factory::Stage.build('production', {"app" => "awesomeapp", "stack" => "bamboo-ree-1.8.7", "addons" => %w[shared-database:5mb custom_domains:basic ssl:piggyback]})
      with_app(subject, 'name' => subject.app) do |app_data| 
        subject.install_addons.map{|a| a['name']}.should include *%w[shared-database:5mb custom_domains:basic ssl:piggyback]
      end
    end
  end
end
end
