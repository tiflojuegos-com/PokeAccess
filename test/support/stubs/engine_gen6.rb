# Minimal stand-ins for the RGSS / mkxp-z / Essentials gen-6 globals the mod hooks into, so the whole
# toolkit loads and runs under a desktop Ruby without the game. Only what the mod touches is stubbed;
# everything returns harmless defaults. This is the gen-6 engine (PB*/PScreen_*); the GameData era has its
# own stub file.

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
  def self.frame_rate; 40; end
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
    def triggerex?(*a); false; end
    def pressex?(*a); false; end
  end
end

module Kernel
  def self.pbMessageDisplay(*a); end
  def self.pbMessage(*a); end
  def self.pbConfirmMessage(*a); false; end
end

module MessageTypes; Kinds = 0; Entries = 1; Items = 2; end
def pbGetMessage(type, id); "msg#{id}"; end
def pbGetMessageFromHash(type, id); "place#{id}"; end
def pbGetMapNameFromId(id); "Mapa #{id}"; end
# MapInfos table for Locator.map_name: a hash of id => object responding to .name.
class TestMapInfo; attr_reader :name; def initialize(id); @name = "Mapa #{id}"; end; end
def pbLoadRxData(path); path =~ /MapInfos/ ? Hash.new { |h, k| h[k] = TestMapInfo.new(k) } : nil; end
def pbHiddenPower(iv); [0, 60]; end
def getID(mod, sym); (mod.const_get(sym) rescue 0); end

module PBItems
  REPEL = 25; RARECANDY = 50; POTION = 1
  def self.getName(id); { 25 => "Repel", 50 => "Caramelo Raro", 1 => "Pocion" }[id] || "Item#{id}"; end
end
module PBSpecies; def self.getName(id); "Especie#{id}"; end; end
module PBMoves;   def self.getName(id); "Mov#{id}"; end; end
module PBTypes;   def self.getName(id); "Tipo#{id}"; end; end
module PBNatures; def self.getName(id); "Naturaleza#{id}"; end; end
module PBAbilities; def self.getName(id); "Habilidad#{id}"; end; end
module PBRibbons; def self.getName(id); "Cinta#{id}"; end; end
module PBStats; def self.getName(s); "Estadistica#{s}"; end; end
class PBMoveData
  def initialize(id); @id = id; end
  def basedamage; 40 + @id.to_i; end
  def accuracy; 100; end
  def type; @id.to_i % 3; end
end

module PBTerrain
  None = 0; Grass = 2; Sand = 3; Water = 7; Waterfall = 8; TallGrass = 10; Ice = 12
  def self.isSurfable?(tag); tag == Water; end
end

module PBEffects
  Reflect = 1; LightScreen = 2; AuroraVeil = 3; Spikes = 4; StealthRock = 5; ToxicSpikes = 6
  Tailwind = 7; StickyWeb = 8; TrickRoom = 9; Gravity = 10
  GrassyTerrain = 11; MistyTerrain = 12; ElectricTerrain = 13; PsychicTerrain = 14
end

class Table; def self._load(s); allocate; end; def _dump(d); ""; end; end
class Color; def self._load(s); allocate; end; def _dump(d); ""; end; end
class Tone;  def self._load(s); allocate; end; def _dump(d); ""; end; end

class Game_Player
  attr_accessor :x, :y, :direction
  def initialize; @x = 5; @y = 5; @direction = 2; end
  def update(*a); end
  def passable?(x, y, dir); ($game_map.passable?(x, y, dir) rescue true); end
  def moving?; false; end
end

# A minimal map event for grid scenarios (x/y/name/sprite/facing -- what the locator reads).
class TestEvent
  attr_accessor :id, :name, :x, :y, :character_name, :direction
  def initialize(id, name, x, y); @id = id; @name = name; @x = x; @y = y; @character_name = "npc"; @direction = 2; end
end

class Game_Map
  attr_accessor :map_id, :width, :height
  def initialize; @map_id = 1; @width = 20; @height = 20; @events = {}; @grid = nil; end
  def events; @events; end
  def terrain_tag(x, y); 0; end

  # Loads an ASCII grid so passable?/counter?/events mirror real walls. '#'=wall, '.'=floor, 'C'=counter,
  # '@'=player start, any other letter/digit = an npc event on that tile. Returns self.
  def load_grid(rows)
    @grid = rows; @height = rows.length; @width = rows.map { |r| r.length }.max; @events = {}; eid = 0
    rows.each_index do |y|
      (0...rows[y].length).each do |x|
        ch = rows[y][x, 1]
        if ch == "@"
          $game_player.x = x; $game_player.y = y
        elsif ch != "#" && ch != "." && ch != "C" && ch =~ /[A-Za-z0-9]/
          eid += 1; @events[eid] = TestEvent.new(eid, "EV#{eid}", x, y)
        end
      end
    end
    self
  end
  def cell(x, y); (@grid && y >= 0 && x >= 0 && @grid[y] && x < @grid[y].length) ? @grid[y][x, 1] : "#"; end
  def counter?(x, y); cell(x, y) == "C"; end
  def blocked?(x, y); c = cell(x, y); c == "#" || c == "C"; end
  def passable?(x, y, dir)
    return true unless @grid
    dx = (dir == 6 ? 1 : (dir == 4 ? -1 : 0)); dy = (dir == 2 ? 1 : (dir == 8 ? -1 : 0))
    !blocked?(x + dx, y + dy)
  end
end

class Game_Temp;   attr_accessor :in_menu, :message_window_showing, :in_battle; end
class Game_System; def map_interpreter; @i ||= Object.new.tap { |o| def o.running?; false; end }; end; end
class Scene_Map;   def update(*a); end; end

# The gen-6 summary scene the readers hook (PokemonSummaryScene#pbUpdate/drawPage*). Defined here so the
# hooks wrap real methods at load; specs set @pokemon and call the method to drive the wiring.
class PokemonSummaryScene
  attr_accessor :pokemon
  def initialize(pk = nil); @pokemon = pk; end
  def pbUpdate(*a); end
  def pbStartScene(*a); end
  def drawPageOne(*a); end
end

$game_player = Game_Player.new
$game_map    = Game_Map.new
$game_temp   = Game_Temp.new
$game_system = Game_System.new
$game_switches = Hash.new(false)
$game_variables = Hash.new(0)
$Trainer = nil
$scene = Scene_Map.new
$stats = nil
$PokemonGlobal = Object.new
def $PokemonGlobal.surfing; false; end
def $PokemonGlobal.diving; false; end
def $PokemonGlobal.bridge; 0; end
