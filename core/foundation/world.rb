module PokeAccess
  # One door to the running game's globals ($game_map, $game_player, $player/$Trainer, $PokemonBag...). Two
  # reasons it exists: readers should not reach for a raw global (the names differ by engine, e.g. $player vs
  # $Trainer, and a typo is a silent NameError on a global), and reading them in one place means an error
  # (not a normal nil) is logged once instead of swallowed. Each accessor returns the object or nil; nil is a
  # normal state (title screen, no save loaded) and is NOT logged. A reader that has reached a point where a
  # global must exist and finds nil can call want(key, value) to leave one diagnostic line -- that is where
  # "the reader went quiet" becomes traceable, without flooding the log with expected title-screen nils.
  module World
    # The active map ($game_map), or nil before a map is loaded.
    def self.map; fetch(:map) { $game_map }; end

    # The on-map player event ($game_player), or nil off-map.
    def self.player_char; fetch(:player_char) { $game_player }; end

    # The trainer object, engine-independent ($player on the GameData era, $Trainer on gen-6). Delegates to
    # Engine.player, which knows both names.
    def self.player; PokeAccess::Engine.player; end

    # The bag ($PokemonBag, or $player.bag on engines that moved it onto the player), or nil.
    def self.bag; fetch(:bag) { (defined?($PokemonBag) && $PokemonBag) ? $PokemonBag : (player.bag rescue nil) }; end

    # The cross-map save data ($PokemonGlobal), or nil.
    def self.pokemon_global; fetch(:pokemon_global) { $PokemonGlobal }; end

    # The map metadata for the current (or given) map id, or nil.
    def self.map_metadata(map_id = nil)
      mid = map_id || (map.map_id rescue nil)
      return nil unless mid
      (GameData::MapMetadata.try_get(mid) rescue nil) || (pbGetMetadata(mid, 0) rescue nil)
    rescue StandardError
      nil
    end

    # True when on a map with a player (the normal field state). Readers that touch map/player can gate on
    # this instead of repeating the nil checks.
    def self.on_map?
      !map.nil? && !player_char.nil?
    end

    # Runs the block and returns its value, or nil on error (a missing global raises NameError when the name
    # is undefined on some engines). A nil result is NOT logged here -- absence is a normal state -- but a
    # genuine error is logged once so an engine mismatch is not swallowed.
    def self.fetch(key)
      yield
    rescue StandardError => e
      PokeAccess.log_once("world.#{key}", e)
      nil
    end

    # Returns value, logging once when it is nil. Call this only at a point where the global was expected to
    # exist (so the log line means "a reader went quiet because X was missing", not a routine title-screen
    # nil). param key a short tag for the diagnostic line; param value the looked-up object
    def self.want(key, value)
      PokeAccess.log_once("world.want.#{key}", "expected but absent") if value.nil?
      value
    rescue StandardError
      value
    end
  end
end
