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

module Essentials; VERSION = "21.1"; end

module Game_Player_GD; end
class Game_Player
  attr_accessor :x, :y, :direction
  def initialize; @x = 5; @y = 5; @direction = 2; end
  def update(*a); end
  def passable?(x, y, dir); ($game_map.passable?(x, y, dir) rescue true); end
  def moving?; false; end
end

class TestEvent
  attr_accessor :id, :name, :x, :y, :character_name, :direction
  def initialize(id, name, x, y); @id = id; @name = name; @x = x; @y = y; @character_name = "npc"; @direction = 2; end
end

class Game_Map
  attr_accessor :map_id, :width, :height
  def initialize; @map_id = 1; @width = 20; @height = 20; @events = {}; @grid = nil; end
  def events; @events; end
  def terrain_tag(x, y); 0; end
  def passable?(x, y, dir); true; end
end

class Game_Temp;   attr_accessor :in_menu, :message_window_showing, :in_battle; end
class Game_System; def map_interpreter; @i ||= Object.new.tap { |o| def o.running?; false; end }; end; end
class Scene_Map;   def update(*a); end; end

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
