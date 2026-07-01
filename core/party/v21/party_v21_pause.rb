# Modern (v21+) pause menu trigger: reset the info key to read the trainer when the pause menu opens, so it
# does not read a stale :pokemon left over from the party screen or a previous battle. Spoken content is the
# agnostic PokeAccess::Party / Info; this only wires the modern scene. No-op on gen-6 (lacks this scene).
PokeAccess::Hooks.after_hook("PokemonPauseMenu_Scene", :pbStartScene) do |_s, _r, _a|
  PokeAccess::Info.set_info(:trainer, nil)
end
