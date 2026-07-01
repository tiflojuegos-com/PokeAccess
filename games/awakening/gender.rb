module PokeAccess
  # Awakening's player gender pick (PokemonGenderSelection in "Gender selection"): two sprites (boy/girl)
  # with no text; left selects boy, right girl, C confirms. The cursor is @select (1 = none yet, 2/3 = boy,
  # 4/5 = girl) and the whole thing blocks inside initialize, so it is never $scene. An around-hook holds the
  # live instance and a per-frame poll reads @select, speaking the focused gender when it changes (deduped).
  module AwakeningGender
    @scene = nil
    @last = nil

    # Holds the live picker while its blocking initialize runs; cleared on exit.
    def self.holding(scene); @scene = scene; @last = nil; end
    def self.released; @scene = nil; @last = nil; end

    # Reads the focused gender when @select changes on the held picker.
    def self.poll
      s = @scene
      return unless s
      sel = (s.instance_variable_get(:@select) rescue nil)
      return if sel.nil? || sel == @last
      @last = sel
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

PokeAccess::Game.define("awakening") do
  around("PokemonGenderSelection", :initialize) do |scene, call_next, _a|
    PokeAccess::AwakeningGender.holding(scene)
    begin; call_next.call; ensure; PokeAccess::AwakeningGender.released; end
  end
  poll_each_frame { PokeAccess::AwakeningGender.poll }
end
