module PokeAccess
  # Ready Menu (registered key-items quick selector, PokemonReadyMenu_Scene): its item buttons are sprites
  # driven by a hidden command window whose index is mirrored to @index, so the generic reader never sees
  # it. Reads the focused item name on change. @commands holds [item_id, name] pairs.
  module ReadyMenu
    def self.poll(scene)
      PokeAccess::Menus.poll_sprite_menu(scene, :@commands, :@access_ready_last) { |entry| (entry[1] rescue nil) }
    end
  end
end

# pbUpdate runs each frame and syncs @index from the hidden command window; read the focus on change.
PokeAccess::Hooks.after_hook("PokemonReadyMenu_Scene", :pbUpdate) do |scene, _r, _a|
  PokeAccess::ReadyMenu.poll(scene)
end
