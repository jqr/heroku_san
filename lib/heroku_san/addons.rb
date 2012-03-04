module HerokuSan
  class Addons
    def initialize stage
      @stage = stage
    end

    attr_reader :stage

    # Addons that are in the heroku_san configuration, but not installed.
    #   => ['not:installed', 'also:not']
    def needed
      stage.addons - installed
    end

    # A list of addons that are installed, but not broken.
    #   => ['addon:name', 'another:addon', 'broken:name', 'another:broken']
    def installed
      all_installed.collect { |x| x.first }
    end

    # A list of addons that are not configured correctly, with a URL where the problem can be inspected and/or fixed.
    #   => [['broken:name', 'http://heroku.com/blah/blah'], ['another:broken', 'http://heroku.com/blah/blah/again']]
    def broken
      all_installed.select { |x| x.length == 2 }
    end

    def refresh
      @caches = nil
    end

    private
    def all_installed
      caches[:all_installed] ||=
        begin
          `heroku addons --app #{stage.app}`.lines.collect do |line|
            line = line.chomp
            if line.empty? || line =~ /^-/
              nil
            else
              line.split /\s+/
            end
          end.compact
        end
    end

    def caches
      @caches ||= {}
    end
  end
end
