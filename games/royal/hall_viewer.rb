module PokeAccess
  # royal's Hall of Fame PC viewer ([ROYAL] Hall de la Fama -> HallOfFameViewerScene): browse past Hall
  # entries (teams). @hallEntry is the current entry (array of Pokemon), @pokemonIndex the focused member,
  # @hallIndex the entry. update_display redraws on each navigation, so read the focused Pokemon (name,
  # species, level) plus its position, deduped by [entry, member].
  module RoyalHallViewer
    def self.read(scene)
      entry = PokeAccess.ivar(scene, :@hallEntry)
      return unless entry.is_a?(Array)
      pi = PokeAccess.ivar_i(scene, :@pokemonIndex)
      hi = PokeAccess.ivar_i(scene, :@hallIndex)
      key = [hi, pi]
      return unless PokeAccess::Cursor.changed?(scene, :hof, key)
      pk = (entry[pi] rescue nil)
      return unless pk
      total = ($PokemonGlobal.hallOfFame.size rescue 0)
      num = ($PokemonGlobal.hallOfFameLastNumber + hi - total + 1 rescue (hi + 1))
      parts = ["Registro #{num}", "#{pi + 1} de #{entry.length}"]
      nm = (pk.name rescue nil)
      parts.push(nm) if nm && !nm.to_s.empty?
      sp = (GameData::Species.get(pk.species).name rescue nil)
      parts.push(sp) if sp && sp != nm
      lv = (pk.level rescue nil)
      parts.push("nivel #{lv}") if lv
      PokeAccess.speak_clean(parts.join(", "), true)
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("royal") do
  after("HallOfFameViewerScene", :update_display) { |scene, _r, _a| PokeAccess::RoyalHallViewer.read(scene) }
end
