# Currydex (royal's [ROYAL] Curry plugin): Window_Currydex is a Window_DrawableCommand, but its entries
# are [number, name] pairs, which the generic reader skips (pairs read as nil for safety), so the list was
# silent. This extractor reads the focused recipe -- its number and name, or "no descubierto" for one not
# yet found, mirroring what the screen draws.
PokeAccess::Game.define("royal") do
  screen_reader("Window_Currydex") do |win, i|
    cmds = win.instance_variable_get(:@commands)
    next nil unless cmds.is_a?(Array) && cmds[i]
    num = cmds[i][0].to_i; name = cmds[i][1]
    (pbCurryRegistered?(cmds[i][0]) rescue false) ? "#{num + 1}, #{name}" : "#{num + 1}, no descubierto"
  end
end
