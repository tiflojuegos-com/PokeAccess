module PokeAccess
  # Sprite-button pause menus: a fangame addon that replaces PokemonMenu_Scene with a custom bezier/sprite
  # panel (no command window). selectButton(index) fires on open and on every cursor move over @buttons (an
  # array of [key, label] pairs), so reading the focused label there voices the whole menu, opening
  # included, with no duplication. A profile with this menu opts in with SpriteButtonMenu.define(game).
  module SpriteButtonMenu
    # Registers the selectButton reader for a game profile.
    def self.define(game)
      PokeAccess::Game.define(game) do
        after("PokemonMenu_Scene", :selectButton) do |scene, _r, args|
          idx = args[0]
          buttons = PokeAccess.ivar(scene, :@buttons)
          next unless buttons.is_a?(Array) && idx && idx >= 0 && idx < buttons.length
          label = (buttons[idx][1] rescue nil)
          PokeAccess.speak_clean(label.to_s, true) if label && !label.to_s.empty?
        end
      end
    end
  end
end
