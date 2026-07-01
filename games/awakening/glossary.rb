module PokeAccess
  # Awakening's diary glossary (Scene_Glosario in "Diario de Liam Lana"): a sprite tab menu with @commands
  # (Historia, Personajes) and an @index cursor moved by up/down in a blocking loop INSIDE main -- so it is
  # never $scene. An around-hook on main holds the live instance, and a per-frame poll reads @index off it,
  # speaking the focused tab when it changes (deduped).
  module AwakeningGlossary
    @scene = nil
    @last = nil

    # Holds the live glossary while its blocking main runs; cleared on exit.
    def self.holding(scene); @scene = scene; @last = nil; end
    def self.released; @scene = nil; @last = nil; end

    # Reads the focused tab name when @index changes on the held glossary.
    def self.poll
      s = @scene
      return unless s
      idx = (s.instance_variable_get(:@index) rescue nil)
      cmds = (s.instance_variable_get(:@commands) rescue nil)
      return unless idx && cmds.is_a?(Array) && idx >= 0 && idx < cmds.length
      return if idx == @last
      @last = idx
      PokeAccess.speak(PokeAccess.clean(cmds[idx].to_s), true)
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("awakening") do
  around("Scene_Glosario", :main) do |scene, call_next, _a|
    PokeAccess::AwakeningGlossary.holding(scene)
    begin; call_next.call; ensure; PokeAccess::AwakeningGlossary.released; end
  end
  poll_each_frame { PokeAccess::AwakeningGlossary.poll }
end
