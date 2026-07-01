module PokeAccess
  # The Purify Chamber (Shadow-Pokemon / Orre-style games) shows its 9 sets as gauge bars with no text.
  # The set list is a Window_PurifyChamberSets (a Window_DrawableCommand), so the focused set is read as
  # the cursor moves. First pass: the set overview (count, shadow Pokemon, tempo, purifiable); per-position
  # detail comes later, after live testing.
  module PurifyChamber
    # The spoken description of chamber set i: count, the shadow Pokemon if any, tempo vs the maximum,
    # and whether it can be purified now.
    def self.set_text(chamber, i)
      return nil unless chamber
      parts = [PokeAccess::I18n.t(:pchm_set, :n => i.to_i + 1)]
      cnt = (chamber.setCount(i) rescue nil)
      cnt = (chamber[i].length rescue nil) if cnt.nil?
      if cnt && cnt.to_i <= 0
        parts.push(PokeAccess::I18n.t(:pchm_empty))
        return parts.join(", ")
      end
      parts.push(PokeAccess::I18n.t(:pchm_count, :n => cnt)) if cnt
      sh = (chamber.getShadow(i) rescue nil)
      nm = (sh.name rescue nil) if sh
      parts.push(PokeAccess::I18n.t(:pchm_shadow, :name => nm)) if nm && !nm.to_s.empty?
      tempo = (chamber[i].tempo rescue nil)
      maxt = (chamber.class.maximumTempo rescue nil)
      parts.push(PokeAccess::I18n.t(:pchm_tempo, :n => tempo, :max => maxt)) if tempo && maxt
      parts.push(PokeAccess::I18n.t(:pchm_purifiable)) if (chamber.isPurifiable?(i) rescue false)
      parts.join(", ")
    rescue StandardError
      nil
    end
  end
end

# The set sidebar (Window_PurifyChamberSets, a Window_DrawableCommand): the generic reader sees no text
# (sets are drawn as gauges), so read the focused set's overview as the cursor moves. No-op in games
# without a Purify Chamber.
PokeAccess::Menus.def_extractor("Window_PurifyChamberSets") do |win, i|
  PokeAccess::PurifyChamber.set_text(win.instance_variable_get(:@chamber), i)
end
