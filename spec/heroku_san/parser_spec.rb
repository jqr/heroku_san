require 'spec_helper'

module HerokuSan
  describe HerokuSan::Parser do
    describe "#create_config" do
      context "using the heroku_san format" do
        let(:parser) { HerokuSan::Parser.new(File.join(SPEC_ROOT, "fixtures", "old_format.yml")) }

        it "returns a list of apps" do
          parser.parse.keys.should =~ %w[production staging demo]
        end
      end

      context "unknown project" do
        let(:template_config_file) do
          path = File.join(SPEC_ROOT, "..", "lib/templates", "heroku.example.yml")
          (File.respond_to? :realpath) ? File.realpath(path) : path
        end

        it "creates a new file using the example file" do
          Dir.mktmpdir do |dir|
            tmp_config_file = File.join dir, 'config.yml'
            parser = HerokuSan::Parser.new(tmp_config_file)
            FileUtils.should_receive(:cp).with(File.expand_path(template_config_file), tmp_config_file)
            parser.create_config.should be_true
          end
        end

        it "does not overwrite an existing file" do
          parser = HerokuSan::Parser.new(File.join(SPEC_ROOT, "fixtures", "example.yml"))
          FileUtils.should_not_receive(:cp)
          parser.create_config.should be_false
        end
      end
    end
  end
end