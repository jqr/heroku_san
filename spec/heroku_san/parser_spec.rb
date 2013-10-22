require 'spec_helper'

module HerokuSan
describe HerokuSan::Parser do
  let(:parser) { subject }

  describe '#parse' do
    context 'using the new format' do
      let(:parseable) { Parseable.new(fixture("example.yml")) }

      it "returns a list of apps" do
        parser.parse(parseable)

        parseable.configuration.keys.should =~ %w[production staging demo]
        parseable.configuration['production'].should == {'app' => 'awesomeapp', 'tag' => 'production/*', 'config' => {'BUNDLE_WITHOUT' => 'development:test', 'GOOGLE_ANALYTICS' => 'UA-12345678-1'}}
        parseable.configuration['staging'].should == {'app' => 'awesomeapp-staging', 'stack' => 'bamboo-ree-1.8.7', 'config' => {'BUNDLE_WITHOUT' => 'development:test'}}
        parseable.configuration['demo'].should == {'app' => 'awesomeapp-demo', 'stack' => 'cedar', 'config' => {'BUNDLE_WITHOUT' => 'development:test'}}
      end
    end

    context "using the old heroku_san format" do
      let(:parseable) { Parseable.new(fixture("old_format.yml")) }

      it "returns a list of apps" do
        parser.parse(parseable)

        parseable.configuration.keys.should =~ %w[production staging demo]
        parseable.configuration.should == {
            'production' => {'app' => 'awesomeapp', 'config' => {}},
            'staging' => {'app' => 'awesomeapp-staging', 'config' => {}},
            'demo' => {'app' => 'awesomeapp-demo', 'config' => {}}
        }
      end
    end
  end

  describe "#convert_from_heroku_san_format" do
    let(:old_format) { {'apps' => {'production' => 'awesomeapp', 'staging' => 'awesomeapp-staging', 'demo' => 'awesomeapp-demo'}} }
    let(:new_format) { {'production' => {'app' => 'awesomeapp'}, 'staging' => {'app' => 'awesomeapp-staging'}, 'demo' => {'app' => 'awesomeapp-demo'}} }

    it "converts to the new hash" do
      parser.settings = old_format
      expect {
        parser.convert_from_heroku_san_format
      }.to change(parser, :settings).to(new_format)
    end

    it "doesn't change new format" do
      parser.settings = new_format
      expect {
        parser.convert_from_heroku_san_format
      }.not_to change(parser, :settings)
    end
  end

  describe "#merge_external_config" do
    let(:stages) { [double(:name => 'production', :config => prod_config), double(:name => 'staging', :config => staging_config)] }
    let(:prod_config) { double('Production Config') }
    let(:staging_config) { {'EXTRA' => 'bar'} }
    let(:extras) { {'production' => {'EXTRA' => 'bar'}, 'staging' => {'EXTRA' => 'foo'}} }

    context "with no extras" do
      let(:parseable) { double :external_configuration => nil }

      it "doesn't change prod_config" do
        prod_config.should_not_receive :merge!
        parser.merge_external_config! parseable, stages
      end
    end

    context "with extra" do
      let(:parseable) { double :external_configuration => 'config_repos' }
      before(:each) do
        parser.should_receive(:git_clone).with('config_repos', anything)
        parser.should_receive(:parse_yaml).and_return(extras)
      end

      it "merges extra configuration bits" do
        prod_config.should_receive(:merge!).with extras['production']
        parser.merge_external_config! parseable, [stages.first]
      end

      it "overrides the main configuration" do
        parser.merge_external_config! parseable, [stages.last]
        staging_config.should == {"EXTRA" => "foo"}
      end
    end
  end
end
end
