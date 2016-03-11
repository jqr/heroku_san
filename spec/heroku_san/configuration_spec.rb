require 'spec_helper'

module HerokuSan
describe HerokuSan::Configuration do
  let(:configurable) { Configurable.new }
  let(:configuration) { HerokuSan::Configuration.new(configurable, Factory::Stage) }

  describe "#stages" do
    it "creates a configuration hash" do
      configuration.configuration = {'production' => {}}
      expect(configuration.stages).to eq(
          'production' => Factory::Stage.build('production', 'deploy' => HerokuSan::Deploy::Rails)
      )
    end

    it "configures the deploy strategy" do
      configurable.options = {'deploy' => HerokuSan::Deploy::Base}
      configuration.configuration = {'production' => {}}
      expect(configuration.stages).to eq(
          'production' => Factory::Stage.build('production', 'deploy' => HerokuSan::Deploy::Base)
      )
    end
  end

  describe "#generate_config" do
    context "unknown project" do
      it "creates a new file using the example file" do
        Dir.mktmpdir do |dir|
          configurable.config_file = tmp_config_file = File.join(dir, 'config.yml')
          expect(FileUtils).to receive(:cp).with(configuration.template, tmp_config_file)
          expect(configuration.generate_config).to be_truthy
        end
      end

      it "does not overwrite an existing file" do
        expect(FileUtils).not_to receive(:cp)
        configurable.config_file = fixture("example.yml")
        expect(configuration.generate_config).to be_falsey
      end
    end
  end
end
end
