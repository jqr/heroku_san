require 'spec_helper'
require 'tmpdir'

module HerokuSan
describe HerokuSan::Project do
  let(:heroku_san) { HerokuSan::Project.new }
  subject { heroku_san }
  before do
    HerokuSan::Configuration.new(Configurable.new, Factory::Stage).tap do |config|
      config.configuration = {'production' => {}, 'staging' => {}, 'demo' => {}}
      heroku_san.configuration = config
    end
  end

  describe "#apps constructs the deploy list" do
    it "appends known shorthands to apps" do
      expect(heroku_san.apps).to eq []
      heroku_san << 'production'
      expect(heroku_san.apps).to eq %w[production]
      heroku_san << 'staging'
      expect(heroku_san.apps).to eq %w[production staging]
      heroku_san << 'unknown'
      expect(heroku_san.apps).to eq %w[production staging]
    end
  
    it "appends .all (or any array)" do
      heroku_san << heroku_san.all
      expect(heroku_san.apps).to eq heroku_san.all
    end
  
    describe "extra (default) behaviors" do
      specify "on a git branch that matches an app name" do
        expect(heroku_san).to receive(:git_active_branch) { "staging" }
        expect($stdout).to receive(:puts).with("Defaulting to 'staging' as it matches the current branch")
        expect {
          expect(heroku_san.apps).to eq %w[staging]
        }.to change{heroku_san.instance_variable_get('@apps')}.from([]).to(%w[staging])
      end

      specify "on a git branch that doesn't matches an app name" do
        expect(heroku_san).to receive(:git_active_branch) { "master" }
        expect(heroku_san.apps).to eq %w[]
      end
    
      context "with only a single configured app" do        
        before do
          HerokuSan::Configuration.new(Configurable.new).tap do |config|
            config.configuration = {'production' => {}}
            heroku_san.configuration = config
          end
        end

        it "returns the app" do
          expect($stdout).to receive(:puts).with('Defaulting to "production" since only one app is defined')
          expect {
            expect(heroku_san.apps).to eq %w[production]
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
      expect(block).to receive(:action).with(heroku_san['production'])
      heroku_san.each_app do |stage|
        block.action(stage)
      end
    end
  end
  
  describe "#[]" do
    it "returns a config section" do
      heroku_san.all.each do |app|
        expect(heroku_san[app]).to be_a HerokuSan::Stage
      end
    end
  end
end
end
