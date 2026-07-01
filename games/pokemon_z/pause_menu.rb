# Custom pause menu (DP_PauseMenu, script 206 "Menu Mejorado"; sprite-based, not a command window, so the
# generic menu hook does not see it), read by the shared core reader (PokeAccess::DPMenu). :trainer_info
# keeps the contextual trainer info current so the info key reads the trainer while the menu is open.
PokeAccess::Game.define("pokemon_z") do
  after("DP_PauseMenu", :update) do |menu, _r, _a|
    PokeAccess::DPMenu.read(menu, :trainer_info => true)
  end
end
