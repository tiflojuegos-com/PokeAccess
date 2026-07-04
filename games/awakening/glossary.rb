module PokeAccess
  # Awakening's diary glossary (Scene_Glosario in "Diario de Liam Lana"): a sprite tab menu with @commands
  # (Historia, Personajes) and an @index cursor moved by up/down in a blocking loop INSIDE main -- so it is
  # never $scene. An around-hook on main holds the live instance, and a per-frame poll reads @index off it,
  # speaking the focused tab when it changes (deduped).
  module AwakeningGlossary
    @scene = nil

    # SceneWatcher.wire interface: hold the live glossary while its blocking main runs, clear on exit.
    def self.watch(scene); @scene = scene; PokeAccess::Cursor.reset(self, :tab); end
    def self.unwatch; @scene = nil; PokeAccess::Cursor.reset(self, :tab); end

    # Reads the focused tab name when @index changes on the held glossary.
    def self.poll
      s = @scene
      return unless s
      idx = PokeAccess.ivar(s, :@index)
      cmds = PokeAccess.ivar(s, :@commands)
      return unless idx && cmds.is_a?(Array) && idx >= 0 && idx < cmds.length
      PokeAccess::Cursor.announce(self, :tab, idx) { cmds[idx].to_s }
    rescue StandardError
      nil
    end
  end
end

PokeAccess::SceneWatcher.wire("Scene_Glosario", :main, PokeAccess::AwakeningGlossary)
