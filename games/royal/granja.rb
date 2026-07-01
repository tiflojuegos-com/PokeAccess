# royal's Secret Base / farm decorating ([ROYAL] Granja - decorar tu casa). Two Window_DrawableCommand
# selectors whose labels come from SecretBag / GameData::SecretBaseDecoration, not from a standard ivar, so
# the generic reader skips them:
#   Window_BasePocketsList     -> decoration categories (SecretBag.pocket_names[i]) + count, last = cancel
#   Window_BaseDecorationsList -> decorations in the focused pocket (their names), last = cancel
PokeAccess::Game.define("royal") do
  screen_reader("Window_BasePocketsList") do |win, i|
    count = SecretBag.pocket_count
    next PokeAccess::I18n.t(:pc_cancel) if i >= count
    nm  = (SecretBag.pocket_names[i] rescue nil)
    next nil if nm.nil? || nm.to_s.empty?
    bag = win.instance_variable_get(:@bag)
    cur = (bag.current_pocket_size(i + 1) rescue nil)
    mx  = (bag.max_pocket_size(i + 1) rescue 0)
    qty = (mx && mx > 0) ? "#{cur} de #{mx}" : (cur ? cur.to_s : nil)
    qty ? "#{nm}, #{qty}" : nm
  end

  screen_reader("Window_BaseDecorationsList") do |win, i|
    bag    = win.instance_variable_get(:@bag)
    pocket = win.instance_variable_get(:@pocket)
    items  = (bag.pockets[pocket] rescue nil)
    next PokeAccess::I18n.t(:pc_cancel) if items.is_a?(Array) && i >= items.length
    next nil unless items.is_a?(Array) && items[i]
    nm = (GameData::SecretBaseDecoration.get(items[i][0]).name rescue nil)
    next nil if nm.nil? || nm.to_s.empty?
    (bag.is_placed?(pocket, i) rescue false) ? "#{nm}, colocado" : nm
  end

  # Walls & floors variant (008_ParedesSuelos.rb): the same two selectors over SecretBagParedesSuelos,
  # whose decoration names live in GameData::SecretBaseDecorationParedSuelo, not the standard table.
  screen_reader("Window_BasePocketsListParedSuelo") do |win, i|
    count = SecretBagParedesSuelos.pocket_count
    next PokeAccess::I18n.t(:pc_cancel) if i >= count
    nm  = (SecretBagParedesSuelos.pocket_names[i] rescue nil)
    next nil if nm.nil? || nm.to_s.empty?
    bag = win.instance_variable_get(:@bag)
    cur = (bag.current_pocket_size(i + 1) rescue nil)
    mx  = (bag.max_pocket_size(i + 1) rescue 0)
    qty = (mx && mx > 0) ? "#{cur} de #{mx}" : (cur ? cur.to_s : nil)
    qty ? "#{nm}, #{qty}" : nm
  end

  screen_reader("Window_BaseDecorationsParedSueloList") do |win, i|
    bag    = win.instance_variable_get(:@bag)
    pocket = win.instance_variable_get(:@pocket)
    items  = (bag.pockets[pocket] rescue nil)
    next PokeAccess::I18n.t(:pc_cancel) if items.is_a?(Array) && i >= items.length
    next nil unless items.is_a?(Array) && items[i]
    nm = (GameData::SecretBaseDecorationParedSuelo.get(items[i][0]).name rescue nil)
    next nil if nm.nil? || nm.to_s.empty?
    (bag.is_placed?(pocket, i) rescue false) ? "#{nm}, colocado" : nm
  end
end
