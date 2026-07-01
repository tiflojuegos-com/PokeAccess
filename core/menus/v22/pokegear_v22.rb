# v22 Pokegear main menu (PokemonPokegear_Scene): a radial menu of PokegearButton sprites, not a command
# window, navigated with UP/DOWN over @index with the options in @commands (each [image, name]). The
# generic command-window hook never sees it, so poll the focused button name each frame, deduped. pbUpdate
# refreshes the selection every frame. No-op where the class is absent (only v22 games have it).
PokeAccess::Hooks.after_hook("PokemonPokegear_Scene", :pbUpdate) do |scene, _r, _a|
  PokeAccess::Menus.poll_sprite_menu(scene, :@commands, :@access_pg_last) { |entry| (entry[1] rescue nil) }
end
