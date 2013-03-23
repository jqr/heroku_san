require 'spec_helper'

describe HerokuSan::Parser do
  describe "#parse" do
    context "using the heroku_san format" do
      let(:parser) { HerokuSan::Parser.new(File.join(SPEC_ROOT, "fixtures", "old_format.yml")) }

      it "returns a list of apps" do
        parser.parse.keys.should =~ %w[production staging demo]
      end
    end
  end
end