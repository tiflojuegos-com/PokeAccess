# BerryDex (royal's [ROYAL] TDW Berry Core and Dex): Window_Berrydex is a Window_DrawableCommand whose
# entries are [berry_id, name, indexNumber] triples, which the generic reader skips, so the list was
# silent. This reads the focused berry -- its dex number and name, or "no descubierto" for one not yet
# registered (pbBerryRegistered?), mirroring drawItem.
PokeAccess::Game.define("royal") do
  screen_reader("Window_Berrydex") do |win, i|
    cmds = win.instance_variable_get(:@commands)
    next nil unless cmds.is_a?(Array) && cmds[i]
    id = cmds[i][0]; num = cmds[i][2].to_i; name = cmds[i][1]
    (pbBerryRegistered?(id) rescue false) ? "#{num}, #{name}" : "#{num}, no descubierto"
  end
end

# Berry detail (BerrydexInfo_Scene): drawPage(page) draws a section (1 info, 2 plant, 3 battle, 4
# mutations) for @berry as sprites/positioned text. Announce the berry name, the section, and (on the info
# page) its description on each page change; the deeper per-page data (growth, mutations) stays visual.
# Pages 3/4 are conditional (a berry with no battle page shifts Mutations to page 3), so the section label
# is chosen from the pages the scene actually shows, not a fixed order.
PokeAccess::Game.define("royal") do
  after("BerrydexInfo_Scene", :drawPage) do |scn, _r, args|
    berry = PokeAccess.ivar(scn, :@berry)
    page  = (args[0] rescue PokeAccess.ivar(scn, :@page))
    next if berry.nil? || !PokeAccess::Cursor.changed?(scn, :bdi, [berry, page])
    name  = (GameData::Item.get(berry).name rescue berry.to_s)
    labels = ["Información", "Planta"]
    labels.push("Combate") if (scn.pbShowBattlePage? rescue true)
    labels.push("Mutaciones") if (scn.pbShowMutationsPage? rescue true)
    section = labels[page.to_i - 1] || page
    parts = [name, "página #{section}"]
    if page == 1
      desc = (GameData::Item.get(berry).description rescue nil)
      parts.push(desc) if desc && !desc.to_s.empty?
    end
    PokeAccess.speak_clean(parts.join(". "), true)
  end
end
