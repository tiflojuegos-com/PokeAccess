module PokeAccess
  # Awakening's player gender pick (PokemonGenderSelection in "Gender selection"): two sprites (boy/girl)
  # with no text; left selects boy, right girl, C confirms. The cursor is @select (1 = none yet, 2/3 = boy,
  # 4/5 = girl) and the whole thing blocks inside initialize, so it is never $scene. An around-hook holds the
  # live instance and a per-frame poll reads @select, speaking the focused gender when it changes (deduped).
  module AwakeningGender
    @scene = nil

    # SceneWatcher.wire interface: hold the live picker while its blocking initialize runs, clear on exit.
    def self.watch(scene); @scene = scene; PokeAccess::Cursor.reset(self, :sel); end
    def self.unwatch; @scene = nil; PokeAccess::Cursor.reset(self, :sel); end

    # Reads the focused gender when @select changes on the held picker.
    def self.poll
      s = @scene
      return unless s
      sel = PokeAccess.ivar(s, :@select)
      return unless PokeAccess::Cursor.changed?(self, :sel, sel)
      key = case sel
            when 2, 3 then :aw_gender_boy
            when 4, 5 then :aw_gender_girl
            else nil
            end
      PokeAccess.speak(PokeAccess::I18n.t(key), true) if key
    rescue StandardError
      nil
    end
  end
end

PokeAccess::SceneWatcher.wire("PokemonGenderSelection", :initialize, PokeAccess::AwakeningGender)
