# Fallback reader for the Diamond/Pearl-style field menu (DP_PauseMenu / PauseMenuDP plugin), for games
# with no bespoke profile. The shared core reader (PokeAccess::DPMenu) reads the focused entry on each
# cursor move; no-op where the class is absent (standard PokemonPauseMenu_Scene menus are read by core).
PokeAccess::Game.define("generic") do
  after("DP_PauseMenu", :update) do |menu, _r, _a|
    PokeAccess::DPMenu.read(menu)
  end
end
