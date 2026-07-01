module PokeAccess
  # Field-move / registered-item selection (Advanced Items - Field Moves plugin,
  # SelectMoveMenu_Scene). A custom button menu: @commands is a list of [id, name, mode, idx]
  # scrolled by @index with no command window, so it is otherwise mute. refresh_buttons runs on
  # each cursor move and pbShowCommands wraps the loop, so the focused option's name is read on
  # open and on navigation, deduped. The name is already a display string (the move/item name).
  module FieldMovesV21
    @last = nil

    def self.reset; @last = nil; end

    # Speaks the focused option's name when it changes.
    def self.read(scene)
      cmds = (scene.instance_variable_get(:@commands) rescue nil)
      idx  = (scene.instance_variable_get(:@index) rescue nil)
      return unless cmds.is_a?(Array) && idx && cmds[idx]
      name = (cmds[idx][1] rescue nil).to_s
      return if name.empty? || name == @last
      @last = name
      PokeAccess.speak(PokeAccess.clean(name), true)
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Hooks.before_hook("SelectMoveMenu_Scene", :pbShowCommands) do |scene, _a|
  PokeAccess::FieldMovesV21.reset
  PokeAccess::FieldMovesV21.read(scene)
end

PokeAccess::Hooks.after_hook("SelectMoveMenu_Scene", :refresh_buttons) do |scene, _r, _a|
  PokeAccess::FieldMovesV21.read(scene)
end
