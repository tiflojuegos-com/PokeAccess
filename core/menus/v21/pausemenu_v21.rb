module PokeAccess
  # GameData-era Essentials field/pause menu (PokemonPauseMenu_Scene#pbShowCommands): reads the highlighted
  # command of its Window_CommandPokemon while the menu runs, polling on Input.update as the cursor moves.
  module PauseMenuV21
    @win = nil
    @last = nil

    # Starts watching the menu's command window (called by SceneWatcher when the menu opens). Receives the
    # scene and extracts its cmdwindow sprite.
    def self.watch(scene); @win = ((scene.instance_variable_get(:@sprites) || {})["cmdwindow"] rescue nil); @last = nil; end

    # Stops watching (called when the menu closes).
    def self.unwatch; @win = nil; @last = nil; end

    # Reads the highlighted command when the cursor moves. Uses the index METHOD (not the @index ivar,
    # whose name varies) and the generic list introspector (handles @commands/@list/... and string/symbol/
    # object entries), so it reads command windows regardless of how a fork (Sky, Map Zoom...) stores them.
    def self.poll
      w = @win
      return unless w
      idx = (w.index rescue (w.instance_variable_get(:@index) rescue nil))
      return if idx.nil? || idx < 0 || idx == @last
      @last = idx
      t = (PokeAccess::Menus.generic_focus(w, idx) rescue nil)
      PokeAccess.speak(PokeAccess.clean(t), true) if t && !t.to_s.empty?
    rescue StandardError
      nil
    end
  end
end

# Hold the command window for the menu loop and poll the cursor each frame, via the shared wiring helper
# (the around-hook + per-frame poll boilerplate). No-op on gen-6, which lacks this scene.
PokeAccess::SceneWatcher.wire("PokemonPauseMenu_Scene", :pbShowCommands, PokeAccess::PauseMenuV21)
