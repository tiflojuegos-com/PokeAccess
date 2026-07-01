# The field menu in this build is the PauseMenuDP plugin (DP_PauseMenu), a Diamond/Pearl style icon menu
# read by the shared core reader (PokeAccess::DPMenu). The trainer-card entry's label is the player's own
# name (DP convention), so :relabel_trainer_card speaks it as "Tarjeta de entrenador" for clarity.
PokeAccess::Game.define("anil") do
  after("DP_PauseMenu", :update) do |menu, _r, _a|
    PokeAccess::DPMenu.read(menu, :relabel_trainer_card => true)
  end
end
