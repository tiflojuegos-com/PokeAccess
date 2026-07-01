module PokeAccess
  # Challenge/randomizer rule editors (Challenge Modes and Randomizer plugins): both build a
  # Window_CommandPokemon_Challenge, a checkbox list where each entry is a rule name with an ACTIVADO/
  # DESACTIVADO toggle drawn beside it, plus a trailing "Confirmar". The toggle is held in @text_key (or,
  # before the window splits them, as [name, toggle] pairs in @commands), so the generic hook reads the
  # name but not the state; this extractor adds it. Guarded by the class existing, so other fangames are
  # unaffected. Its own module (not core's PokeAccess::Menus) so this game extractor never collides with
  # the shared menu helpers.
  module AnilMenus
    # The focused rule with its on/off state, or a plain trailing option (Confirmar).
    def self.challenge_rule_text(win, i)
      cmds = win.instance_variable_get(:@commands)
      keys = win.instance_variable_get(:@text_key)
      c = (cmds[i] rescue nil)
      name = c.is_a?(Array) ? c[0] : c
      tog  = c.is_a?(Array) ? c[1] : (keys[i] rescue nil)
      return (name.is_a?(String) ? name : nil) if tog.nil?
      state = (tog == 1) ? PokeAccess::I18n.t(:val_on) : PokeAccess::I18n.t(:val_off)
      name.is_a?(String) ? "#{name}, #{state}" : nil
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("anil") do
  screen_reader("Window_CommandPokemon_Challenge") { |win, i| PokeAccess::AnilMenus.challenge_rule_text(win, i) }
end
