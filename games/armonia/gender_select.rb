# Armonia new-game gender selection (PokemonGenderSelection). The two choices are images, so @select
# tracks the highlight (2 = boy, 4 = girl; 1 the neutral start), changed in input on left/right. Announce
# the highlight as it changes, plus the controls once on open. The confirm prompt is a pbMessage the core
# dialogue hook already reads.
PokeAccess::Game.define("armonia") do
  before("PokemonGenderSelection", :main_method) do |_scene, _args|
    PokeAccess.speak("Elige tu aspecto. Izquierda para chica, derecha para chico, luego acepta.", true)
  end

  after("PokemonGenderSelection", :input) do |scene, _result, _args|
    sel = scene.instance_variable_get(:@select)
    unless sel == scene.instance_variable_get(:@pa_last)
      scene.instance_variable_set(:@pa_last, sel)
      label = { 2 => "Chico", 3 => "Chico", 4 => "Chica", 5 => "Chica" }[sel]
      PokeAccess.speak(label, true) if label
    end
  end
end
