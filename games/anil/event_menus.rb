module PokeAccess
  # Anil's new-game flow uses event-scripted picture menus (Show Picture in map events, no window and no
  # text), so the only readable signal is the picture name; the focused option shows a "...Sel" variant.
  # Register those names with PictureCues so they are announced on navigation (learned by dumping Map104:
  # var 104 = 1 clasico / 2 competitivo / 3 random). Add more here as other event picture-menus are mapped.
end

PokeAccess::Game.define("anil") do
  picture_texts(
    "MenuClasSel" => :ev_mode_classic,
    "MenuCompSel" => :ev_mode_competitive,
    "MenuRandSel" => :ev_mode_random
  )
end
