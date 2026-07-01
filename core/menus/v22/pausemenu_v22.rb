# v22 pause menu (Essentials v22: UI::PauseMenuVisuals). Its command list is a Window_CommandPokemon that
# the screen reads by index and may leave inactive, so the active-only generic reader can miss it. Mark the
# window so the generic reader skips it (no double read), and read the focused command here on the visuals'
# per-frame update, deduped by index. @commands is [[ids], [names]].
if PokeAccess::V22.const_exists?("UI::PauseMenuVisuals")
  PokeAccess::Hooks.after_hook("UI::PauseMenuVisuals", :set_commands) do |vis, _ret, _args|
    win = (vis.instance_variable_get(:@sprites)[:commands] rescue nil)
    win.instance_variable_set(:@ignore_input, true) if win
  end

  PokeAccess::Hooks.after_hook("UI::PauseMenuVisuals", :update_visuals) do |vis, _ret, _args|
    cmds = (vis.instance_variable_get(:@commands) rescue nil)
    win  = (vis.instance_variable_get(:@sprites)[:commands] rescue nil)
    next unless win && cmds && cmds[1]
    idx = (win.index rescue nil)
    next unless idx && idx >= 0
    next if idx == (vis.instance_variable_get(:@access_pause_idx) rescue nil)
    vis.instance_variable_set(:@access_pause_idx, idx)
    name = cmds[1][idx]
    PokeAccess.speak(name.to_s, true) if name && !name.to_s.empty?
  end
end
