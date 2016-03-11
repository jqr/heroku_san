require 'spec_helper'

module HerokuSan
  STOCK_CONFIG = {"BUNDLE_WITHOUT"=>"development:test", "LANG"=>"en_US.UTF-8", "RACK_ENV"=>"production"}

describe HerokuSan::Stage do
  include HerokuSan::Git
  subject { Factory::Stage.build('production', {"deploy" => HerokuSan::Deploy::Rails, "app" => "awesomeapp", "stack" => "cedar"})}
  before do
    allow_any_instance_of(HerokuSan::API).to receive(:preflight_check_for_cli)
  end

  context "initializes" do
    subject { Factory::Stage.build('production',
      {"stack" => "cedar", 
       "app"   => "awesomeapp-demo", 
       "tag"   => "demo/*", 
       "config"=> {"BUNDLE_WITHOUT"=>"development:test"},
       "addons"=> ['one:addon', 'two:addons']
      })}

    it { expect(subject.name).to eq 'production' }
    it { expect(subject.app).to eq 'awesomeapp-demo' }
    it { expect(subject.stack).to eq 'cedar' }
    it { expect(subject.tag).to eq "demo/*" }
    it { expect(subject.config).to eq("BUNDLE_WITHOUT"=>"development:test") }
    it { expect(subject.repo).to eq 'git@heroku.com:awesomeapp-demo.git' }
    it { expect(subject.addons).to eq ['one:addon', 'two:addons'] }
  end
  
  describe "#app" do
    it { expect(subject.app).to eq 'awesomeapp'}
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
        expect(subject.stack).to eq 'bamboo-mri-1.9.2'
      end
    end
  
    it "returns the stack name from the config when it is set there" do
      subject = Factory::Stage.build('production', {"app" => "awesomeapp", "stack" => "cedar"})
      expect(subject.stack).to eq 'cedar'
    end
  end

  describe '#addons' do
    subject { Factory::Stage.build('production', {'addons' => addons}) }
    context 'default' do
      let(:addons) { nil }
      it { expect(subject.addons).to eq [] }
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
      it { expect(subject.addons).to eq [ 'a', 'b', 'other' ] }
    end
  end

  describe "#run" do
    it "runs commands using the new cedar format" do
      expect(subject.heroku).to receive(:system).with("heroku", "run", "worker foo bar bleh", "--app", "awesomeapp", "--exit-code") { true }
      subject.run 'worker foo bar bleh'
    end
  end

  describe "#push" do
    it "deploys to heroku" do
      expect(subject).to receive(:git_parsed_tag).with(nil) {'tag'}
      expect(subject).to receive(:git_push).with('tag', subject.repo, [])
      subject.push
    end
    
    it "deploys with a custom sha" do
      expect(subject).to receive(:git_push).with('deadbeef', subject.repo, [])
      subject.push('deadbeef')
    end
    
    it "deploys with --force" do
      expect(subject).to receive(:git_parsed_tag).with(nil) {'tag'}
      expect(subject).to receive(:git_push).with('tag', subject.repo, %w[--force])
      subject.push(nil, :force)
    end
    
    it "deploys with a custom sha & --force" do
      expect(subject).to receive(:git_push).with('deadbeef', subject.repo, %w[--force])
      subject.push('deadbeef', :force)
    end
  end

  describe "#migrate" do
    it "runs rake db:migrate" do
      with_app(subject, 'name' => subject.app) do |app_data|
        expect(subject).to receive(:run).with('rake db:migrate').and_return 'output:'
        expect(subject.migrate).to eq "restarted"
      end
    end
  end
  
  describe "#deploy" do
    context "using the default strategy" do
      it "(rails) pushes & migrates" do
        allow_any_instance_of(HerokuSan::Deploy::Rails).to receive(:deploy)
        subject.deploy
      end
    end

    context "using a custom strategy" do
      class TestDeployStrategy < HerokuSan::Deploy::Base
        def deploy; end
      end
      subject = Factory::Stage.build('test', {"app" => "awesomeapp", "deploy" => TestDeployStrategy})
      it "(custom) calls deploy" do
        expect_any_instance_of(TestDeployStrategy).to receive(:deploy)
        subject.deploy
      end
    end
  end
  
  describe "#maintenance" do
    it ":on" do
      with_app(subject, 'name' => subject.app )do |app_data|
        expect(subject.maintenance(:on).status).to eq 200
      end
    end

    it ":off" do
      with_app(subject, 'name' => subject.app) do |app_data|
        expect(subject.maintenance(:off).status).to eq 200
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
          expect(subject.heroku).to receive(:post_app_maintenance).with(subject.app, '1').ordered
          reactor = double("Reactor"); expect(reactor).to receive(:scram).with(:now).ordered
          expect(subject.heroku).to receive(:post_app_maintenance).with(subject.app, '0').ordered
          
          subject.maintenance {reactor.scram(:now)} 
        end
      end

      it "ensures that maintenance mode is turned off" do
        with_app(subject, 'name' => subject.app) do |app_data|
          expect(subject.heroku).to receive(:post_app_maintenance).with(subject.app, '1').ordered
          reactor = double("Reactor"); expect(reactor).to receive(:scram).and_raise(RuntimeError)
          expect(subject.heroku).to receive(:post_app_maintenance).with(subject.app, '0').ordered
          
          expect do subject.maintenance {reactor.scram(:now)} end.to raise_error StandardError
        end
      end
    end
  end

  describe "#create" do
    after do
      subject.heroku.delete_app(@app)
    end

    it "uses the provided name" do
      expect((@app = subject.create)).to eq 'awesomeapp'
    end

    it "creates an app on heroku" do
      subject = Factory::Stage.build('production')
      expect(@app = subject.create).to match /generated-name-\d+/
    end

    it "uses the default stack if none is given" do
      subject = Factory::Stage.build('production')
      expect(@app = subject.create).to match /generated-name-\d+/
      expect(subject.heroku.get_stack(@app).body.detect{|stack| stack['current']}['name']).to eq 'bamboo-mri-1.9.2'
    end

    it "uses the stack from the config" do
      expect(@app = subject.create).to eq 'awesomeapp'
      expect(subject.heroku.get_stack(@app).body.detect{|stack| stack['current']}['name']).to eq 'cedar'
    end
  end
  
  describe "#long_config" do
    it "returns the remote config" do
      with_app(subject, 'name' => subject.app) do |app_data|
        expect(subject.long_config).to eq STOCK_CONFIG
      end
    end
  end

  describe "#push_config" do
    it "updates the configuration settings on Heroku" do
      subject = Factory::Stage.build('test', {"app" => "awesomeapp", "config" => {'FOO' => 'bar', 'DOG' => 'emu'}})
      with_app(subject, 'name' => subject.app) do |app_data|
        expect(subject.push_config).to eq STOCK_CONFIG.merge('FOO' => 'bar', 'DOG' => 'emu')
      end
    end

    it "pushes the options hash" do
      subject = Factory::Stage.build('test', {"app" => "awesomeapp", "config" => {'FOO' => 'bar', 'DOG' => 'emu'}})
      with_app(subject, 'name' => subject.app) do |app_data|
        expect(subject.push_config('RACK_ENV' => 'magic')).to eq STOCK_CONFIG.merge('RACK_ENV' => 'magic')
      end
    end
  end

  describe "#restart" do
    it "restarts an app" do
      with_app(subject, 'name' => subject.app) do |app_data|
        expect(subject.restart).to eq 'restarted'
      end
    end
  end
  
  describe "#logs" do
    it "returns log files" do
      expect(subject.heroku).to receive(:system).with("heroku", "logs", "--app", "awesomeapp", "--exit-code") { true }
      subject.logs
    end

    it "tails log files" do
      expect(subject.heroku).to receive(:system).with("heroku", "logs", "--tail", "--app", "awesomeapp", "--exit-code") { true }
      subject.logs(:tail)
    end
  end

  describe "#revision" do
    it "returns the named remote revision for the stage" do
      expect(subject).to receive(:git_revision).with(subject.repo) {"sha"}
      expect(subject).to receive(:git_named_rev).with('sha') {"sha production/123456"}
      expect(subject.revision).to eq 'sha production/123456'
    end

    it "returns nil if the stage has never been deployed" do
      expect(subject).to receive(:git_revision).with(subject.repo) {nil}
      expect(subject).to receive(:git_named_rev).with(nil) {''}
      expect(subject.revision).to eq ''
    end
  end
  
  describe "#installed_addons" do
    it "returns the list of installed addons" do
      with_app(subject, 'name' => subject.app) do |app_data|
        expect(subject.installed_addons.map{|a|a['name']}).to include *%w[shared-database:5mb]
      end
    end
  end

  describe '#install_addons' do
    subject { Factory::Stage.build('production', {"app" => "awesomeapp", "stack" => "bamboo-ree-1.8.7", "addons" => %w[custom_domains:basic ssl:piggyback]})}

    it "installs the addons" do
      with_app(subject, 'name' => subject.app) do |app_data| 
        expect(subject.install_addons.map{|a| a['name']}).to include *%w[custom_domains:basic ssl:piggyback]
        expect(subject.installed_addons.map{|a|a['name']}).to match subject.install_addons.map{|a| a['name']}
      end
    end

    it "only installs missing addons" do
      subject = Factory::Stage.build('production', {"app" => "awesomeapp", "stack" => "bamboo-ree-1.8.7", "addons" => %w[shared-database:5mb custom_domains:basic ssl:piggyback]})
      with_app(subject, 'name' => subject.app) do |app_data| 
        expect(subject.install_addons.map{|a| a['name']}).to include *%w[shared-database:5mb custom_domains:basic ssl:piggyback]
      end
    end
  end
end
end
