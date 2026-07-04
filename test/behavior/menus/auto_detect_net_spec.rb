# Regression: the generic auto-detect SAFETY NET must actually bind. The net hooked "Window_Selectable"
# (menus.rb) and the diagnostic walked :Window_Selectable (input.rb), but NO engine defines that class
# (gen-6/v21/v22 all use SpriteWindow_Selectable); const_at returned nil and the after_hook fell through
# hooks.rb (return if k.nil?) WITHOUT even being recorded in Hooks.missing -- a permanently dead feature the
# old readers_spec never caught, because it exercised only the pure entry_text/generic_focus functions with
# bare anonymous stubs that never touch the real class chain or the hook. These suites drive the REAL chain
# (SpriteWindow_Selectable -> SpriteWindow_SelectableEx -> Window_DrawableCommand, from the engine stub) so
# the net is wired end to end. The fake windows set @index then call update, exactly as the game does on a
# cursor move.

# (a) The net binds to the real class and reads a generic selectable that has no dedicated extractor: setting
# @index and calling update speaks the focused option, introspected from the window's own list (never OCR).
# Also asserts the dead token is gone: const_at("Window_Selectable") is nil while the real class resolves.
Suite.define("menus: auto-detect net binds to SpriteWindow_Selectable and reads a generic selectable") do
  truthy "the real selectable class exists in the engine",
         !PokeAccess.const_at("SpriteWindow_Selectable").nil?
  truthy "the dead token resolves to nothing (the bug)",
         PokeAccess.const_at("Window_Selectable").nil?
  truthy "the net's update is actually wrapped (the saved-original alias exists, so it is not a no-op)",
         SpriteWindow_Selectable.private_method_defined?(:update__pa_orig_SpriteWindow_Selectable) ||
         SpriteWindow_Selectable.method_defined?(:update__pa_orig_SpriteWindow_Selectable)
  falsy "the net binding was not swallowed into Hooks.missing",
        PokeAccess::Hooks.missing.include?("SpriteWindow_Selectable#update")

  win = Class.new(SpriteWindow_Selectable) do
    def initialize(items); super(); @items = items; end
  end.new(["Correr", "Luchar", "Objetos"])
  prev = PokeAccess::Config.auto_detect
  PokeAccess::Config.auto_detect = true
  begin
    win.index = 1
    win.update
    spoke "the net speaks the focused generic option", /Luchar/
    SpeakCapture.clear
    win.index = 2
    win.update
    spoke "moving the cursor re-reads via the net", /Objetos/
    SpeakCapture.clear
    win.update
    silent "an unchanged index does not repeat (deduped per instance)"
  ensure
    PokeAccess::Config.auto_detect = prev
  end
end

# (b) No double read: a Window_DrawableCommand is announced ONCE, by the dedicated command hook -- the net
# hook also fires (its parent update runs via super, the documented onion) but its is_a?(Window_DrawableCommand)
# guard makes the body no-op, so the entry is not spoken twice. This is the interaction the fix must preserve.
Suite.define("menus: the net does not double-read a Window_DrawableCommand already covered by the sibling") do
  prev = PokeAccess::Config.auto_detect
  PokeAccess::Config.auto_detect = true
  begin
    cmd = Window_DrawableCommand.new(["Guardar", "Salir"])
    cmd.index = 0
    cmd.update
    spoke_once "a command-window entry is announced exactly once (no net + sibling overlap)", /Guardar/
  ensure
    PokeAccess::Config.auto_detect = prev
  end
end

# (c) The net stays silent when auto-detect is off and over garbage entries (pairs/ids), so turning the
# feature off is honoured and the reader never voices raw non-text -- the conservative contract, now proven
# through the live hook rather than only the pure function.
Suite.define("menus: the net respects the auto_detect flag and stays silent on non-text entries") do
  win = Class.new(SpriteWindow_Selectable) do
    def initialize(items); super(); @items = items; end
  end.new(["Uno", "Dos"])
  prev = PokeAccess::Config.auto_detect

  PokeAccess::Config.auto_detect = false
  begin
    win.index = 1
    win.update
    silent "with auto_detect off the net says nothing"
  ensure
    PokeAccess::Config.auto_detect = prev
  end

  garbage = Class.new(SpriteWindow_Selectable) do
    def initialize(rows); super(); @items = rows; end
  end.new([[1, 2], [3, 4]])
  PokeAccess::Config.auto_detect = true
  begin
    garbage.index = 0
    garbage.update
    silent "the net stays silent over pair/id rows (never speaks garbage)"
  ensure
    PokeAccess::Config.auto_detect = prev
  end
end
