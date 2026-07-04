module PokeAccess
  # royal's language selector ([ROYAL] Selector de Idiomas -> LanguageOption_Scene). Its command list is a
  # Window_CommandPokemonNoScroll (a Window_CommandPokemon subclass the generic Window_DrawableCommand reader
  # does not see), whose update_cursor_rect runs on every cursor move. Read the focused command there,
  # deduped by index; the commands are the language names plus an optional "SALIR".
  module RoyalLanguage
    def self.read(win)
      idx = (win.index rescue -1)
      return if idx < 0
      return unless PokeAccess::Cursor.changed?(win, :lang, idx)
      cmds = PokeAccess.ivar(win, :@commands)
      t = (cmds.is_a?(Array) && cmds[idx]) ? cmds[idx].to_s : nil
      PokeAccess.speak_clean(t, true) if t && !t.empty?
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("royal") do
  after("Window_CommandPokemonNoScroll", :update_cursor_rect) { |win, _r, _a| PokeAccess::RoyalLanguage.read(win) }
end
