# v22 Pokegear main menu (PokemonPokegear_Scene): a radial menu of PokegearButton sprites, not a command
# window, navigated with UP/DOWN over @index with the options in @commands (each [image, name]). The
# generic command-window hook never sees it. Vanilla v21 and v22 both ship this scene, and there the
# PokegearButton#selected= hook (menus/v21/ui_v21.rb) already reads the focused button, so this pbUpdate
# poll (each frame, deduped) registers only when that path is absent: forks that drop the button sprites.
unless PokeAccess::Engine.has?("PokegearButton#selected=")
  PokeAccess::Hooks.after_hook("PokemonPokegear_Scene", :pbUpdate) do |scene, _r, _a|
    PokeAccess::Menus.poll_sprite_menu(scene, :@commands, :pg_last) { |entry| (entry[1] rescue nil) }
  end
end
