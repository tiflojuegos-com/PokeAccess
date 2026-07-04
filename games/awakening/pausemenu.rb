module PokeAccess
  # Awakening's Fates pause menu (JessFatesMenu in "Menu Inicio"): a vertical strip of sprite panels
  # (FatesMenuPanels, each with @nombre/@index) plus icon shortcuts. JessFatesMenu blocks inside its own
  # initialize, so it is never $scene; navigation is a local variable, but each panel is told its focus via
  # cambio(true/false), and the initially focused panel marks itself in its own initialize
  # (@pnl.src_rect.y == 37). So: read a panel when cambio(true) fires, and read the initially focused panel
  # when it is created. A panel's name (@nombre) is the spoken label.
  module AwakeningPause
    # Reads a panel that has just become focused via cambio(true).
    def self.panel_changed(panel, focused)
      say_panel(panel) if focused == true
    end

    # Reads a freshly created panel if it is the initially focused one (its sprite row is the highlight row).
    def self.panel_created(panel)
      hl = (panel.instance_variable_get(:@pnl).src_rect.y rescue 0)
      say_panel(panel) if hl == 37
    rescue StandardError
      nil
    end

    # Speaks a panel's name.
    def self.say_panel(panel)
      nm = PokeAccess.ivar(panel, :@nombre)
      PokeAccess.speak_clean(nm.to_s, true) if nm && !nm.to_s.empty?
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("awakening") do
  after("FatesMenuPanels", :initialize) do |panel, _r, _a|
    PokeAccess::AwakeningPause.panel_created(panel)
  end
  after("FatesMenuPanels", :cambio) do |panel, _r, args|
    PokeAccess::AwakeningPause.panel_changed(panel, args[0])
  end
end
