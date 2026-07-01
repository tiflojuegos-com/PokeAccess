# Regression: the map name was spammed forever by a cache/event loop (the :map_changed reset cleared
# @last_map_id, which made announce_map_change see a change again next frame). It must announce ONCE per
# real map change, and again only when the map id actually changes.
Suite.define("field: map name announced once per map, not spammed") do
  $game_map.map_id = 35
  PokeAccess::Locator.forget_map
  10.times { PokeAccess::Locator.announce_map_change }
  spoke_once "same map announced exactly once over 10 frames", /Mapa 35/

  SpeakCapture.clear
  $game_map.map_id = 40
  5.times { PokeAccess::Locator.announce_map_change }
  spoke_once "new map announced once after the id changes", /Mapa 40/
end

Suite.define("field: loading re-announces even on the same map") do
  $game_map.map_id = 35
  PokeAccess::Locator.forget_map
  PokeAccess::Locator.announce_map_change
  spoke "map announced on entry", /Mapa 35/
  SpeakCapture.clear
  PokeAccess::Locator.forget_map
  PokeAccess::Locator.announce_map_change
  spoke "re-announced after forget_map on the same map (load case)", /Mapa 35/
end
