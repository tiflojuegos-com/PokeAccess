# Ice sliding: stepping onto ice must carry the search to where the slide stops (one key press), either the
# first non-ice tile or the last ice tile before a wall -- never a wall. step_target must return that slide
# end so the route lands the player where they will actually come to rest.
Suite.define("pathfinder: ice slide stops at floor or last ice before a wall") do
  ice_map = Class.new do
    attr_reader :map_id
    def initialize; @map_id = 777; end
    def terrain_tag(x, y, *_); (y == 3 && x >= 2 && x <= 5) ? 12 : 0; end
    def valid?(x, y); x >= 0 && y >= 0 && x < 9 && y < 7; end
    def width; 9; end
    def height; 7; end
  end
  ice_player = Class.new do
    attr_accessor :x, :y, :far
    def initialize(far); @x = 1; @y = 3; @far = far; end
    def floor?(x, y); y == 3 && x >= 1 && x <= @far; end
    def passable?(x, y, d)
      dl = { 8 => [0, -1], 2 => [0, 1], 4 => [-1, 0], 6 => [1, 0] }[d]
      dl ? floor?(x + dl[0], y + dl[1]) : false
    end
  end

  old_map = $game_map; old_pl = $game_player
  $game_map = ice_map.new; $game_player = ice_player.new(6)
  PokeAccess::Pathfinder.instance_variable_set(:@pcache_state, nil)
  slide = PokeAccess::Pathfinder.ice_slide(2, 3, 1, 0, 6)
  eq "slide stops at the first floor past the ice", slide, [6, 3]
  st = PokeAccess::Pathfinder.step_target(1, 3, [1, 0, 6], false, false)
  eq "step_target returns the slide end", st, [6, 3]

  $game_player = ice_player.new(5)
  PokeAccess::Pathfinder.instance_variable_set(:@pcache_state, nil)
  slide2 = PokeAccess::Pathfinder.ice_slide(2, 3, 1, 0, 6)
  eq "slide stops at the last ice when a wall blocks", slide2, [5, 3]

  $game_map = old_map; $game_player = old_pl
end

# Bridges: off a bridge the engine reports its tiles impassable (water below), so the search must force the
# on-bridge passability to cross -- and restore the real state afterwards, even if the routed block raises
# (otherwise the engine thinks the player is permanently on a bridge, a save-corruption-class bug).
Suite.define("pathfinder: bridges crossed off-bridge with guaranteed restore") do
  bridge_map = Class.new do
    attr_reader :map_id
    def initialize; @map_id = 778; end
    def terrain_tag(x, y, *_); (y == 3 && x >= 2 && x <= 5) ? 15 : 0; end
    def valid?(x, y); x >= 0 && y >= 0 && x < 9 && y < 7; end
    def width; 9; end
    def height; 7; end
  end
  bridge_player = Class.new do
    attr_accessor :x, :y
    def initialize; @x = 1; @y = 3; end
    def stand?(x, y)
      return false unless y == 3 && x >= 1 && x <= 6
      return ($PokemonGlobal.bridge rescue 0) > 0 if x >= 2 && x <= 5
      true
    end
    def passable?(x, y, d)
      dl = { 8 => [0, -1], 2 => [0, 1], 4 => [-1, 0], 6 => [1, 0] }[d]
      dl ? stand?(x + dl[0], y + dl[1]) : false
    end
  end

  old_map = $game_map; old_pl = $game_player; old_pg = $PokemonGlobal
  pg = Object.new
  def pg.surfing; false; end
  def pg.diving; false; end
  class << pg; attr_accessor :bridge; end
  pg.bridge = 0
  $PokemonGlobal = pg; $game_map = bridge_map.new; $game_player = bridge_player.new
  PokeAccess::Pathfinder.instance_variable_set(:@rs_key, nil)
  PokeAccess::Config.route_reach = 128; PokeAccess::Config.astar_max = 5000
  route = PokeAccess::Pathfinder.find_path(6, 3)
  truthy "routes across the bridge from off-bridge", route && !route.empty?
  eq "restores PokemonGlobal.bridge to 0", pg.bridge, 0

  pg.bridge = 0; raised = false
  begin; PokeAccess::Pathfinder.with_bridges { raise "boom" }; rescue StandardError; raised = true; end
  truthy "restores the bridge state even when the block raises", pg.bridge == 0 && raised

  $PokemonGlobal = old_pg; $game_map = old_map; $game_player = old_pl
end
