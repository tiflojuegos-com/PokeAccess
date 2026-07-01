# Resets the mod's mutable module state between suites, so a suite cannot leak into the next and a failure
# points at its own cause (the tracing the runner is built for). Each call clears the per-run caches, the
# contextual info, the battle reference, the locator's map memory, the cursor dedup table, the test map
# (id + events, which key the per-map lever/push caches), and the speak log.
module Reset
  # Runs before each suite. Every reset is guarded so a not-yet-loaded module never aborts the run.
  def self.between_suites
    (PokeAccess::Caches.reset_all rescue nil)
    (PokeAccess::Info.set_info(nil, nil) rescue nil)
    (PokeAccess::Battle.clear_battle rescue nil)
    (PokeAccess::Battle.battle_ended rescue nil)
    (PokeAccess::Locator.forget_map rescue nil)
    (PokeAccess::Cursor.instance_variable_set(:@global, {}) rescue nil)
    (reset_map rescue nil)
    (SpeakCapture.clear rescue nil)
  rescue StandardError
    nil
  end

  # Restores a fresh test map (id 1, no events) and player position, so the per-map caches keyed on map_id
  # (lever/push) never carry events from a previous suite.
  def self.reset_map
    return unless $game_map
    $game_map.map_id = 1
    ($game_map.events.clear if $game_map.respond_to?(:events) && $game_map.events.is_a?(Hash))
    ($game_player.x = 5; $game_player.y = 5) if $game_player
  end
end
