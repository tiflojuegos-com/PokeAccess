# royal's post-battle EXP panel ([ROYAL] MEP -> class Swdfm_Exp_Screen): a non-navigable animated display
# of each party member's exp gain and any level-ups (@values[i] is the exp about to be added to party[i]).
# Announce the gains once when the panel is built (draw_party), and each level-up as it animates
# (redraw_level fires once per level gained, after @levels[i] is bumped to the new level).
PokeAccess::Game.define("royal") do
  after("Swdfm_Exp_Screen", :draw_party) do |scr, _ret, _args|
    unless (scr.instance_variable_get(:@access_mep) rescue false)
      scr.instance_variable_set(:@access_mep, true)
      vals = PokeAccess.ivar(scr, :@values)
      party = ($player.party rescue nil)
      if party && vals
        lines = []
        party.each_with_index do |pk, i|
          v = vals[i]
          lines.push("#{pk.name} gana #{v} de experiencia") if pk && v && v != 0
        end
        PokeAccess.speak_clean(lines.join(". "), true) unless lines.empty?
      end
    end
  end

  after("Swdfm_Exp_Screen", :redraw_level) do |scr, _ret, args|
    i = args[0]
    party = ($player.party rescue nil)
    levels = PokeAccess.ivar(scr, :@levels)
    if party && levels && i && party[i] && levels[i]
      PokeAccess.speak_clean("#{party[i].name} sube al nivel #{levels[i]}", false)
    end
  end
end
