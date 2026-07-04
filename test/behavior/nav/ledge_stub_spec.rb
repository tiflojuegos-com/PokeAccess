# Verifies the world stub's new opt-in capabilities so later steps can rely on them:
#   - place_ledge models a one-way ledge exactly as the engine does (terrain tag 1, passable only from the
#     high side, direction readable through the tileset-passage surface Pathfinder::ledge_dir_ok? consults),
#   - a blocking event makes its tile impassable (so passable_at? respects it),
#   - both are off by default, so existing suites are unaffected.
# It asserts the faithful engine surface only (ledge_jump, the search primitive, must succeed from the high
# side); it deliberately does NOT assert step_target crossing a ledge, which is a live bug a later step fixes.
Suite.define("stub: place_ledge models a faithful one-way ledge") do
  pf = PokeAccess::Pathfinder
  ter = PokeAccess::Terrain
  PokeAccess::Config.route_cache = false
  PokeAccess::Config.ledge_directions = true

  # A downward ledge at (5,7): jumped from above going down.
  $game_map.place_ledge(5, 7, 2)

  eq "the ledge reads terrain tag 1", $game_map.terrain_tag(5, 7), 1
  truthy "Terrain.ledge_at? sees the placed ledge", ter.ledge_at?(5, 7)
  falsy "a plain tile is not a ledge", ter.ledge_at?(5, 6)

  truthy "the ledge is passable when entered from the high side (moving down)", $game_map.passable?(5, 6, 2)
  falsy "the ledge is not passable when approached from below (moving up)", $game_map.passable?(5, 8, 8)
  falsy "the ledge is not passable when approached from the left (moving right)", $game_map.passable?(4, 7, 6)

  truthy "ledge_dir_ok? permits the hop in the ledge's direction (down)", pf.ledge_dir_ok?(5, 7, 2)
  falsy "ledge_dir_ok? forbids hopping the ledge upward", pf.ledge_dir_ok?(5, 7, 8)
  falsy "ledge_dir_ok? forbids hopping the ledge sideways", pf.ledge_dir_ok?(5, 7, 6)

  # The search primitive itself crosses the ledge from the high side (player at (5,6) jumping down two tiles).
  jump = pf.ledge_jump(5, 6, 0, 1, 2)
  eq "ledge_jump lands two tiles past the ledge from the high side", jump, [5, 8]
  eq "ledge_jump refuses the hop from the wrong side (moving up into it)", pf.ledge_jump(5, 8, 0, -1, 8), nil

  PokeAccess::Config.route_cache = true
end

# A leftward ledge exercises a different passage bit, so the direction mapping is not hard-wired to "down".
Suite.define("stub: place_ledge honours each hop direction") do
  pf = PokeAccess::Pathfinder
  PokeAccess::Config.route_cache = false
  PokeAccess::Config.ledge_directions = true

  $game_map.place_ledge(8, 8, 4)  # hopped to the left, entered from the right
  truthy "a left ledge is passable entering from the right (moving left)", $game_map.passable?(9, 8, 4)
  falsy "a left ledge blocks entering from the left (moving right)", $game_map.passable?(7, 8, 6)
  truthy "ledge_dir_ok? permits the leftward hop", pf.ledge_dir_ok?(8, 8, 4)
  falsy "ledge_dir_ok? forbids the rightward hop over a left ledge", pf.ledge_dir_ok?(8, 8, 6)
  eq "ledge_jump lands two tiles left from the high side", pf.ledge_jump(9, 8, -1, 0, 4), [7, 8]

  PokeAccess::Config.route_cache = true
end

# A blocking event makes its tile impassable through the same passable? the pathfinder uses; a non-blocking
# event (the default) does not, so no existing event-driven suite changes behaviour.
Suite.define("stub: a blocking event makes its tile impassable") do
  ev = World.event(:kind => :npc, :id => 4, :x => 6, :y => 5)
  truthy "a plain event does not block its tile by default", $game_map.passable?(6, 6, 8)

  ev.blocking = true
  falsy "a blocking event blocks entry into its tile from below", $game_map.passable?(6, 6, 8)
  falsy "a blocking event blocks entry into its tile from the side", $game_map.passable?(7, 5, 4)
  truthy "a blocking event does not block a neighbouring free tile", $game_map.passable?(8, 5, 4)
end
