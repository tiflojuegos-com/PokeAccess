# Classic trainer card (PokemonTrainerCard_Scene): a static panel drawn once on open, read all on arrival
# (nothing to navigate). The spoken content is the agnostic TrainerCardData; this only wires the scene.
PokeAccess::Hooks.after_hook("PokemonTrainerCard_Scene", :pbStartScene) do |_s, _r, _a|
  PokeAccess.speak(PokeAccess::TrainerCardData.text, false)
end
