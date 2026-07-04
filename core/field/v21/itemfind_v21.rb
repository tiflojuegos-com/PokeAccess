module PokeAccess
  # Item-received popup (Boonzeet's "Item Find" plugin, PokemonItemFind_Scene): shows the name, icon and
  # description of an item the first time it is found -- a notification, not a menu, so nothing reads it.
  # Speaks the title (name, or "<item> <move>" for a TM) and description it draws, when shown.
  module ItemFindV21
    def self.say(scene)
      sp = PokeAccess.ivar(scene, :@sprites)
      return unless sp
      t = (sp["titlewindow"].text rescue nil)
      d = (sp["descwindow"].text rescue nil)
      parts = [t, d].reject { |x| x.nil? || x.to_s.strip.empty? }
      PokeAccess.speak_clean(parts.join(". "), false) unless parts.empty?
    rescue StandardError
      nil
    end
  end
end

# pbShow builds the title/description windows; read them after.
PokeAccess::Hooks.after_hook("PokemonItemFind_Scene", :pbShow) do |scene, _r, _a|
  PokeAccess::ItemFindV21.say(scene)
end
