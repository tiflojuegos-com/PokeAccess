module PokeAccess
  # Zone banners / signs from the JessLetreros plugin: it replaces the standard signpost with a custom
  # LocationWindow whose initialize receives the place name, so reading that on creation voices every banner
  # the instant it appears. A profile that ships this plugin opts in with LocationBanner.define(game).
  # Queued, so it never cuts an entry cutscene's dialogue.
  module LocationBanner
    # Registers the LocationWindow reader for a game profile.
    def self.define(game)
      PokeAccess::Game.define(game) do
        after("LocationWindow", :initialize) do |_window, _result, args|
          name = args[0].to_s
          PokeAccess.speak(name, false) unless name.strip.empty?
        end
      end
    end
  end
end
