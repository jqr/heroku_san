require 'spec_helper'

describe HerokuSan::Parser do
  let(:parser) { subject }
  let(:old_format) { {'apps' => {'production' => 'awesomeapp', 'staging' => 'awesomeapp-staging', 'demo' => 'awesomeapp-demo'}} }
  let(:new_format) { {'production' => {'app' => 'awesomeapp'}, 'staging' => {'app' => 'awesomeapp-staging'}, 'demo' => {'app' => 'awesomeapp-demo'}} }
  let(:extras) { {'production' => {'EXTRA' => 'bar'}, 'staging' => {'EXTRA' => 'foo'}}}

  Parseable = Struct.new(:config_file, :configuration)

  describe '#parse' do
    context 'using the new format' do
      let(:parseable) { Parseable.new(File.join(SPEC_ROOT, "fixtures", "example.yml")) }
      it "returns a list of apps" do
        parser.parse(parseable)

        parseable.configuration.keys.should =~ %w[production staging demo]
        parseable.configuration['production'].should == {'app' => 'awesomeapp', 'tag' => 'production/*', 'config' => {'BUNDLE_WITHOUT' => 'development:test', 'GOOGLE_ANALYTICS' => 'UA-12345678-1'}}
        parseable.configuration['staging'].should == {'app' => 'awesomeapp-staging', 'stack' => 'bamboo-ree-1.8.7', 'config' => {'BUNDLE_WITHOUT' => 'development:test'}}
        parseable.configuration['demo'].should == {'app' => 'awesomeapp-demo', 'stack' => 'cedar', 'config' => {'BUNDLE_WITHOUT' => 'development:test'}}
      end
    end

    context "using the old heroku_san format" do
      let(:parseable) { Parseable.new(File.join(SPEC_ROOT, "fixtures", "old_format.yml")) }
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

  describe "#merge_extra" do
    context "with no extras" do
      it "doesn't change settings" do
        parser.settings = {'production' => {'config' => {}}}
        expect {
          parser.merge_extra({})
        }.not_to change(parser, :settings)
      end
    end

    context "with extra" do
      it "merges extra configuration bits" do
        parser.settings = {'production' => {'config' => {}}}
        parser.merge_extra(extras)
        parser.settings.should == {"production" => {"config" => {"EXTRA" => "bar"}}}
      end

      it "overrides the main configuration" do
        parser.settings = {'staging' => {'config' => {'EXTRA' => 'bar'}}}
        parser.merge_extra(extras)
        parser.settings.should == {"staging" => {"config" => {"EXTRA" => "foo"}}}
      end
    end
  end

  describe "#external_config" do
    context "with no external repos" do
      before(:each) do
        parser.settings = {'production' => {}}
      end
      it "returns {}" do
        parser.external_config.should == {}
      end
      it "doesn't make any external resource calls" do
        parser.should_not_receive(:git_clone)
        parser.should_not_receive(:parse_yaml)
        parser.external_config.should == {}
      end
    end

    context "with an external repos" do
      before(:each) do
        parser.settings = {'config_repo' => 'external_repos', 'production' => {}}
      end
      it "returns the external data" do
        Dir.should_receive(:mktmpdir).and_yield('/tmpdir')
        parser.should_receive(:git_clone).with('external_repos', '/tmpdir')
        parser.should_receive(:parse_yaml).with('/tmpdir/config.yml').and_return(extras)
        parser.external_config.should == extras
      end
    end
  end
end