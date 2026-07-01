# gen-6 party / storage / pause triggers. The spoken content is the agnostic PokeAccess::Party
# (party_storage.rb at the module root); this file only wires the classic-Essentials scenes, so the
# version-specific hooks live under gen6/ as the module-first layout intends.

# Party selection on classic Essentials: the party scene is PokemonScreen_Scene. Modern (Anil) uses
# PokemonParty_Scene whose pbChangeSelection is a pure index function while the loop sets each panel's
# selected=; reading both would double-speak, so modern reads the party via its own PokemonPartyPanel
# #selected= hook (core/menus/v21/ui_v21.rb).
PokeAccess::Hooks.after_hook("PokemonScreen_Scene", :pbChangeSelection) do |scene, ret, args|
  PokeAccess::Party.announce_party(scene.instance_variable_get(:@party), ret, args[1])
end

# PC storage cursor (pbUpdateOverlay runs whenever the focused slot changes).
PokeAccess::Hooks.after_hook("PokemonStorageScene", :pbUpdateOverlay) do |scene, _r, args|
  PokeAccess::Party.announce_pc(scene, args[0], args[1])
end

# Trainer info via the info key when the classic pause menu opens (so the info key reads the trainer, not a
# stale :pokemon left over from the party screen or a previous battle).
PokeAccess::Hooks.after_hook("PokemonMenu_Scene", :pbStartScene) do |_s, _r, _a|
  PokeAccess::Info.set_info(:trainer, nil)
end
