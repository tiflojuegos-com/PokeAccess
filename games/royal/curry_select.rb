# royal's curry berry picker ([ROYAL] TDW Berry Core and Dex -> Window_ChooseBerryMultiple): a
# Window_DrawableCommand whose entries live in @bag.pockets[5] indexed through @filterlist (not a standard
# list ivar), so the generic command reader skips it. Read the focused berry name and quantity; the index
# past the list is the close button.
PokeAccess::Game.define("royal") do
  screen_reader("Window_ChooseBerryMultiple") do |win, i|
    fl = win.instance_variable_get(:@filterlist)
    next "Cerrar bolsa" if !fl.is_a?(Array) || i >= fl.length
    bag   = win.instance_variable_get(:@bag)
    entry = (bag.pockets[5][fl[i]] rescue nil)
    next nil unless entry
    nm = (GameData::Item.get(entry[0]).name rescue nil)
    next nil if nm.nil? || nm.to_s.empty?
    qty = entry[1]
    if qty
      sel = (win.instance_variable_get(:@scene).selectedBerries.count(GameData::Item.get(entry[0])) rescue 0)
      qty -= sel
    end
    qty ? "#{nm}, #{qty}" : nm
  end
end
