module Factory
  class Stage
    class << self
      def build(stage, options = {})
        HerokuSan::Stage.new(
          stage,
          options.merge({api: HerokuSan::API.new(:api_key => "MOCK", mock: true)})
        )
      end

      alias :new :build
    end
  end
end
