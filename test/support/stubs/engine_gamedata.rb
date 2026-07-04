# Stand-ins for the GameData-era engine (Essentials v17+, Ruby-modern): GameData::* and UI::* present,
# $player instead of $Trainer, so the modern-path readers (v21/v22 triggers, gamedata_trainer_info) load
# and run. Shares the generic engine stubs (Win32/Graphics/Input/Game_*) with the gen-6 file but flips the
# data API on. Selected by PA_ENGINE=gamedata.

class Win32API
  def initialize(*a); end
  def call(*a); 0; end
end

module Audio
  def self.se_play(*a); end
  def self.bgs_play(*a); end
  def self.bgm_play(*a); end
end

module Graphics
  def self.update; end
  def self.frame_rate; 60; end
  def self.transition(*a); end
  def self.freeze; end
end

module Input
  DOWN = 2; LEFT = 4; RIGHT = 6; UP = 8
  A = 11; B = 12; C = 13; X = 14; Y = 15; Z = 16; L = 17; R = 18
  CTRL = 21
  class << self
    def update; end
    def dir4; 0; end
    def dir8; 0; end
    def trigger?(*a); false; end
    def press?(*a); false; end
    def repeat?(*a); false; end
  end
end

def pbGetMessage(type, id); "msg#{id}"; end
def pbGetMessageFromHash(type, id); "place#{id}"; end
module MessageTypes; REGION_LOCATION_NAMES = 13; end

class Table; def self._load(s); allocate; end; def _dump(d); ""; end; end
class Color; def self._load(s); allocate; end; def _dump(d); ""; end; end
class Tone;  def self._load(s); allocate; end; def _dump(d); ""; end; end

module GameData
  class Move
    def self.get(id); new(id); end
    def self.try_get(id); new(id); end
    def initialize(id); @id = id; end
    def name; "Move#{@id}"; end
    def power; 40; end
    def accuracy; 100; end
    def type; :TYPE1; end
    def description; "desc#{@id}"; end
  end
  class Type;    def self.get(i); new(i); end; def initialize(i); @i = i; end; def name; "Type#{@i}"; end; end
  class Item;    def self.get(i); new(i); end; def initialize(i); @i = i; end; def name; "Item#{@i}"; end; def portion_name; "Item#{@i}"; end; def portion_name_plural; "Item#{@i}s"; end; def description; "idesc#{@i}"; end; end
  class Species
    def self.get(i); new(i); end
    def initialize(i); @i = i; end
    def name; "Species#{@i}"; end
    def category; "cat#{@i}"; end
    def pokedex_entry; "dex#{@i}"; end
  end
  class Ability; def self.get(i); new(i); end; def initialize(i); @i = i; end; def name; "Ability#{@i}"; end; end
  class Nature;  def self.get(i); new(i); end; def initialize(i); @i = i; end; def name; "Nature#{@i}"; end; end
  class Status;  def self.get(i); new(i); end; def initialize(i); @i = i; end; def name; "Status#{@i}"; end; end
  class Stat;    def self.get(i); new(i); end; def initialize(i); @i = i; end; def name; "Stat#{@i}"; end; end
  class Ribbon;  def self.get(i); new(i); end; def initialize(i); @i = i; end; def name; "Ribbon#{@i}"; end; def description; "rdesc#{@i}"; end; end
  class MapMetadata; def self.try_get(i); nil; end; end
end

# Minimal stand-in for the v22 summary visuals (Essentials v22: UI::PokemonSummaryVisuals) so the real
# summary_v22 hooks register and can be driven. It reproduces the one behaviour the reader ordering depends
# on: set_party_index mutates the shown Pokemon and then calls refresh INTERNALLY (reentrant hook order).
module UI
  class PokemonSummaryVisuals
    attr_accessor :party, :party_index, :pokemon, :page

    def initialize(party, party_index = 0)
      @party = party
      @party_index = party_index
      @pokemon = party[party_index]
      @page = :info
    end

    def refresh; end

    def set_party_index(new_index)
      return if @party_index == new_index
      @party_index = new_index
      @pokemon = @party[@party_index]
      refresh
    end

    def go_to_next_page(page = :skills)
      @page = page
      refresh
    end

    def refresh_move_cursor; end
    def refresh_ribbon_cursor; end
  end
end

# Minimal stand-in for the v21.1 battle menus (Essentials Battle::Scene::MenuBase + FightMenu) so the real
# battle_v21 hooks register and can be driven. It reproduces the one behaviour the mega-toggle cue depends
# on: setIndexAndMode assigns @mode DIRECTLY (never through the mode= setter), which is exactly why the open
# must prime @access_mega for the first real toggle to be voiced. battler returns nil so read_menu no-ops
# (no move to read), keeping the spec's spoken log to just the mega cue.
module Battle
  class Scene
    class MenuBase
      attr_reader :index, :mode

      def initialize; @index = 0; @mode = 0; end

      def index=(value); @index = value; end

      def mode=(value); @mode = value; end

      def setIndexAndMode(index, mode); @index = index; @mode = mode; end
    end

    class FightMenu < MenuBase
      def battler; nil; end
    end
  end
end

module Essentials; VERSION = "21.1"; end

module Game_Player_GD; end
class Game_Player
  attr_accessor :x, :y, :direction, :jumping
  def initialize; @x = 5; @y = 5; @direction = 2; @jumping = false; end
  def update(*a); end
  def passable?(x, y, dir); ($game_map.passable?(x, y, dir) rescue true); end
  def moving?; false; end
  def jumping?; @jumping; end
end

class TestEvent
  attr_accessor :id, :name, :x, :y, :character_name, :direction, :blocking
  def initialize(id, name, x, y); @id = id; @name = name; @x = x; @y = y; @character_name = "npc"; @direction = 2; @blocking = false; end
end

# Reproduces the surface Terrain/Pathfinder read for one-way ledges: it maps a jump direction to the tileset
# passage byte the real engine would carry (the side OPPOSITE the jump is the only one left open, matching
# Pathfinder::LEDGE_OPP_BIT), and it exposes @passages/@terrain_tags/data[x,y,i] so ledge_passage resolves.
module TestLedge
  # RMXP passage bit blocked per direction (0x01 down, 0x02 left, 0x04 right, 0x08 up); the byte of a ledge
  # leaves only the side opposite the jump open, so ledge_dir_ok? permits exactly that jump direction.
  OPP_BIT = { 2 => 0x08, 8 => 0x01, 4 => 0x04, 6 => 0x02 }
  TILE_BASE = 1000

  # The synthetic tileset tile id for a ledge whose hop direction is dir (a distinct id per direction so each
  # carries its own passage byte).
  def self.tile_id(dir); TILE_BASE + dir; end

  # The passage byte of a ledge with hop direction dir: every side blocked except the one opposite the jump.
  def self.passage(dir); 0x0F & ~(OPP_BIT[dir] || 0); end
end

# A stand-in for RMXP's map data Table (data[x,y,layer]): returns the ledge tile id on layer 0 of a ledge
# tile, 0 elsewhere, which is exactly what ledge_passage walks.
class TestMapData
  def initialize(ledges); @ledges = ledges; end
  def [](x, y, layer)
    d = @ledges[[x, y]]
    (d && layer == 0) ? TestLedge.tile_id(d) : 0
  end
end

class Game_Map
  attr_accessor :map_id, :width, :height

  def initialize; @map_id = 1; @width = 20; @height = 20; @events = {}; @grid = nil; init_ledges; end

  def events; @events; end

  # The terrain tag at (x,y): 1 on a placed ledge (so Terrain.ledge_at? sees it), else 0.
  def terrain_tag(x, y); @ledges[[x, y]] ? 1 : 0; end

  # True while (x,y) is inside the map bounds; ledge_jump needs it to accept a landing tile.
  def valid?(x, y); x >= 0 && y >= 0 && x < @width && y < @height; end

  # Registers a one-way ledge at (x,y) whose hop direction is dir (2/4/6/8): opt-in and mirroring the real
  # engine, the tile is passable ONLY when entered moving in dir (from the high side), reads terrain tag 1,
  # and carries the passage byte that makes ledge_dir_ok? permit exactly dir. Returns self.
  def place_ledge(x, y, dir)
    @ledges[[x, y]] = dir
    tid = TestLedge.tile_id(dir)
    @terrain_tags[tid] = 1
    @passages[tid] = TestLedge.passage(dir)
    self
  end

  # Clears all placed ledges (the reset calls this so a ledge never leaks between suites).
  def clear_ledges; init_ledges; end

  # True if a blocking event occupies (x,y) (a solid event makes its tile impassable, as in the real engine).
  def blocking_event_at?(x, y)
    @events.each_value { |e| return true if e.respond_to?(:blocking) && e.blocking && e.x == x && e.y == y }
    false
  end

  # Passability of a one-step move from (x,y) in dir. A ledge tile is passable only when approached moving in
  # its hop direction (high side); a blocking event blocks the destination; otherwise open (modern stub has
  # no grid harness).
  def passable?(x, y, dir)
    dx = (dir == 6 ? 1 : (dir == 4 ? -1 : 0)); dy = (dir == 2 ? 1 : (dir == 8 ? -1 : 0))
    nx = x + dx; ny = y + dy
    ld = @ledges[[nx, ny]]
    return dir == ld if ld
    return false if blocking_event_at?(nx, ny)
    true
  end

  # Exposes the passage/terrain-tag tables the real Game_Map carries, so ledge_passage can read them.
  def init_ledges; @ledges = {}; @passages = {}; @terrain_tags = {}; @data = TestMapData.new(@ledges); end
  def data; @data; end
end

class Game_Temp;   attr_accessor :in_menu, :message_window_showing, :in_battle; end
class Game_System; def map_interpreter; @i ||= Object.new.tap { |o| def o.running?; false; end }; end; end
class Scene_Map;   def update(*a); end; end

# The selectable-window chain the mod's generic auto-detect net and the command hook bind to, reproduced
# minimally but with the SAME shape as every engine (gen-6/v21/v22): Window_DrawableCommand descends from
# SpriteWindow_Selectable, only the base and the leaf own an #update, and the middle class inherits it. This
# lets menus.rb wrap the real navigation update at load (so the net is not a no-op) and lets specs drive a
# cursor move by setting @index then calling update, exactly as the game does. #index/#active are the
# accessors the net reads. A spec that needs a filtered pocket adds #pocket on a subclass.
class SpriteWindow_Base
  attr_accessor :active, :visible, :index
  def initialize; @active = true; @visible = true; @index = 0; end
  def disposed?; false; end
end
class SpriteWindow_Selectable < SpriteWindow_Base
  def update(*a); @index; end
end
class SpriteWindow_SelectableEx < SpriteWindow_Selectable; end
class Window_DrawableCommand < SpriteWindow_SelectableEx
  attr_accessor :commands
  def initialize(commands = []); super(); @commands = commands; end
  def update(*a); old = self.index; super; refresh if self.index != old; @index; end
  def refresh; end
end

# $player carries the modern trainer fields the readers use.
class TestPlayer
  attr_accessor :name, :money, :character_name, :trainertype, :outfit, :gender
  def initialize; @name = "Tester"; @money = 1000; @character_name = "trchar"; @trainertype = 0; @outfit = 0; @gender = 0; end
  def public_ID; 12345; end
  def badge_count; 3; end
  def numbadges; 3; end
  def party; []; end
  def pokedex; @dex ||= TestDex.new; end
end
class TestDex
  def owned_count; 50; end
  def seen_count; 80; end
  def owned?(s); true; end
  def seen?(s); true; end
end

$game_player = Game_Player.new
$game_map    = Game_Map.new
$game_temp   = Game_Temp.new
$game_system = Game_System.new
$game_switches = Hash.new(false)
$game_variables = Hash.new(0)
$player = TestPlayer.new
$scene = Scene_Map.new
$stats = Object.new
def $stats.play_time; 3661; end
$PokemonGlobal = Object.new
def $PokemonGlobal.surfing; false; end
def $PokemonGlobal.diving; false; end
def $PokemonGlobal.bridge; 0; end
