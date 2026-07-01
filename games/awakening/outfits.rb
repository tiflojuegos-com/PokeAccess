module PokeAccess
  # Awakening's class/outfit picker (Fates_Menu_Personajes in "Menu Outfits"): left/right move @select over
  # @classArray (readable class names) for character @name, in a blocking loop INSIDE initialize -- so it is
  # never $scene. An around-hook on initialize holds the live instance while it runs, and a per-frame poll
  # reads @select off it, speaking the focused class (plus locked state) when it changes (deduped).
  module AwakeningOutfits
    @scene = nil
    @last = nil

    # Holds the live picker while its blocking initialize runs; cleared on exit.
    def self.holding(scene)
      @scene = scene
      @last = nil
    end
    def self.released; @scene = nil; @last = nil; end

    # Reads the focused class name (plus locked state) when @select changes on the held picker.
    def self.poll
      s = @scene
      return unless s
      sel = (s.instance_variable_get(:@select) rescue nil)
      arr = (s.instance_variable_get(:@classArray) rescue nil)
      name = (s.instance_variable_get(:@name) rescue nil)
      return unless sel && arr.is_a?(Array) && sel >= 0 && sel < arr.length
      return if sel == @last
      @last = sel
      cls = arr[sel].to_s
      return if cls.empty?
      unlocked = (::Fates_Utilities.checkIfHasClass(name, arr[sel]) rescue true)
      txt = unlocked ? cls : "#{cls}, #{PokeAccess::I18n.t(:aw_outfit_locked)}"
      PokeAccess.speak(PokeAccess.clean(txt), true)
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("awakening") do
  around("Fates_Menu_Personajes", :initialize) do |scene, call_next, _a|
    PokeAccess::AwakeningOutfits.holding(scene)
    begin; call_next.call; ensure; PokeAccess::AwakeningOutfits.released; end
  end
  poll_each_frame { PokeAccess::AwakeningOutfits.poll }
end
