module PokeAccess
  # Awakening's class/outfit picker (Fates_Menu_Personajes in "Menu Outfits"): left/right move @select over
  # @classArray (readable class names) for character @name, in a blocking loop INSIDE initialize -- so it is
  # never $scene. An around-hook on initialize holds the live instance while it runs, and a per-frame poll
  # reads @select off it, speaking the focused class (plus locked state) when it changes (deduped).
  module AwakeningOutfits
    @scene = nil

    # SceneWatcher.wire interface: hold the live picker while its blocking initialize runs, clear on exit.
    def self.watch(scene); @scene = scene; PokeAccess::Cursor.reset(self, :sel); end
    def self.unwatch; @scene = nil; PokeAccess::Cursor.reset(self, :sel); end

    # Reads the focused class name (plus locked state) when @select changes on the held picker.
    def self.poll
      s = @scene
      return unless s
      sel = PokeAccess.ivar(s, :@select)
      arr = PokeAccess.ivar(s, :@classArray)
      name = PokeAccess.ivar(s, :@name)
      return unless sel && arr.is_a?(Array) && sel >= 0 && sel < arr.length
      return unless PokeAccess::Cursor.changed?(self, :sel, sel)
      cls = arr[sel].to_s
      return if cls.empty?
      unlocked = (::Fates_Utilities.checkIfHasClass(name, arr[sel]) rescue true)
      txt = unlocked ? cls : "#{cls}, #{PokeAccess::I18n.t(:aw_outfit_locked)}"
      PokeAccess.speak_clean(txt, true)
    rescue StandardError
      nil
    end
  end
end

PokeAccess::SceneWatcher.wire("Fates_Menu_Personajes", :initialize, PokeAccess::AwakeningOutfits)
