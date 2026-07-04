# Relict's radial pause menu (ArcyGame edit of PokemonPauseMenu_Scene: a 6-button ring, no command window,
# so the standard pause/generic readers never see it). @index (0-5) is the cursor and update_button redraws
# the highlighted button on every move; the buttons are images, so the spoken label is mapped from the index
# following the screen's own `case @index` (party / bag / encounters / save / options / return to checkpoint).
module PokeAccess
  module RelictMenu
    RADIAL = ["Equipo", "Mochila", "Encuentros", "Guardar", "Opciones", "Volver al punto de control"]
  end
end

PokeAccess::Game.define("relict") do
  after("PokemonPauseMenu_Scene", :update_button) do |scene, _ret, _args|
    idx = PokeAccess.ivar(scene, :@index)
    if idx && idx >= 0 && PokeAccess::Cursor.changed?(scene, :radial, idx)
      label = PokeAccess::RelictMenu::RADIAL[idx]
      PokeAccess.speak(label, true) if label && !label.to_s.empty?
    end
  end
end
