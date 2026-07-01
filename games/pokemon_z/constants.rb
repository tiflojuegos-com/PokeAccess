# Pokemon Z 2.18 profile: only what differs from core/foundation/config.rb. Everything generic (keys,
# categories, volumes, astar_max, status/weather tables) lives in core, so a per-game file cannot shadow
# it with stale values. Expressed through the adapter API (PokeAccess::Game).
PokeAccess::Game.define("pokemon_z") do
  # Per-game button relabels for the remap menu (Z maps X/Y/Z to its field actions); added to the core
  # defaults, never replacing them.
  button_labels :x => "Pokevial", :y => "PokeRider", :z => "DexNav"

  # The gym beam puzzle uses rayosAzulesV / rayosRojosV sprites as impassable barriers. Registered as a
  # hazard so they read as "beam" (not a generic npc) and the positional audio gives them the zap cue.
  hazard(/rayos/i, :loc_beam)
end
