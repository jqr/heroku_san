require 'spec_helper'

describe HerokuSan::Parser do
  let(:parser) { subject }
  Parseable = Struct.new(:config_file, :configuration)

  describe "#parse" do
    context "using the heroku_san format" do
      let(:parseable) { Parseable.new(File.join(SPEC_ROOT, "fixtures", "old_format.yml")) }

      it "returns a list of apps" do
        parser.parse(parseable)
        parseable.configuration.keys.should =~ %w[production staging demo]
      end
    end
  end
end