# Internal warps (destination is the current map: staircases, within-map transfers) used to be spoken as
# "exit to <this very map>", useless for orientation, and pisar one was silent because the map id never
# changes. Now they are named "passage to the <dir>" and stepping one announces "you moved to the <dir>".
def mk_warp(id, x, y, dmap, dx, dy)
  pg = TestPage.new(:trigger => 1, :sprite => "", :list => [TestCmd.new(201, [0, dmap, dx, dy])])
  TestGameEvent.new(:id => id, :x => x, :y => y, :name => "EV#{id}", :pages => [pg], :active_page => pg)
end

Suite.define("locator: internal warps are named as a passage with a direction") do
  loc = PokeAccess::Locator
  def $game_map.width; 98; end
  def $game_map.height; 35; end
  mid = $game_map.map_id

  inner = mk_warp(11, 21, 5, mid, 89, 14)  # destination on the same map, to the east
  outer = mk_warp(7, 69, 3, 999, 70, 10)   # destination on another map

  eq "same-map warp reads as a passage with cardinal", PokeAccess::I18n.t(:loc_passage_dir, :dir => PokeAccess::I18n.t(:dir_e)), loc.target_name(inner)
  match "other-map warp still reads as an exit", loc.target_name(outer), /salida a/
  eq "centre point has no cardinal", nil, loc.cardinal_of(49, 17)
end

Suite.define("locator: stepping an internal warp announces the teleport") do
  loc = PokeAccess::Locator
  def $game_map.width; 98; end
  def $game_map.height; 35; end
  setp = lambda { |x, y| $game_player.instance_variable_set(:@x, x); $game_player.instance_variable_set(:@y, y) }

  setp.call(21, 5); loc.announce_internal_teleport  # seed position
  SpeakCapture.clear
  setp.call(22, 5); loc.announce_internal_teleport
  silent "walking one tile is not a teleport"

  SpeakCapture.clear
  setp.call(89, 14); loc.announce_internal_teleport
  spoke "a same-map jump announces the move", /te has movido al este/
end
