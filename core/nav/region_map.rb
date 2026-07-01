module PokeAccess
  # Region map / fast travel: pbGetMapLocation(x,y) gives the place name under the cursor, announced on change.
  module RegionMap
    # Announces the place name under the cursor when the square changes.
    def self.announce(name, x, y)
      key = [x, y]
      return if key == @last
      @last = key
      n = name.to_s.strip
      PokeAccess.speak(n, true) unless n.empty?
    end

    # Clears the dedup so reopening the map reads the first square even if the cursor lands on the same one
    # it closed on.
    def self.reset; @last = nil; end
  end
end

# Two class names in the wild for the same gen-6-style region map with pbGetMapLocation(x, y): the
# vanilla/Reminiscencia "PokemonRegionMapScene" and the underscore variant "PokemonRegionMap_Scene" used
# by Arcky's Region Map (royal) and Añil. Each hook no-ops where its class is absent. (v22 uses
# UI::TownMapVisuals, handled in nav/v22/town_map_v22.)
["PokemonRegionMapScene", "PokemonRegionMap_Scene"].each do |cn|
  PokeAccess::Hooks.after_hook(cn, :pbGetMapLocation) do |_s, ret, args|
    PokeAccess::RegionMap.announce(ret, args[0], args[1])
  end
  PokeAccess::Hooks.before_hook(cn, :pbStartScene) { |_s, _a| PokeAccess::RegionMap.reset }
end
