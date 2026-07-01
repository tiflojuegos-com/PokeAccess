# Vanilla v21.1 Move Relearner (MoveRelearner_Scene), for games that do NOT use the BetterMoveRelearner
# plugin (those use UI::MoveReminderVisuals, read via screen_v22). Its move list is a Window_CommandPokemon
# whose names the generic reader already voices, but the focused move's detail (type/power/accuracy/pp/desc)
# is hand-drawn in pbDrawMoveList. The scene exposes the same @pokemon/@moves/@sprites["commands"] shape as
# the egg-move tutor, so reuse SkyEggMove.detail (defined in menus/skyflyer/eggmove; referenced at runtime,
# so load order does not matter). Mute the generic bare-name read and speak the full detail on each redraw.
PokeAccess::Hooks.after_hook("MoveRelearner_Scene", :pbStartScene) do |scene, _r, _a|
  w = ((scene.instance_variable_get(:@sprites) || {})["commands"] rescue nil)
  w.instance_variable_set(:@ignore_input, true) if w
end
PokeAccess::Hooks.after_hook("MoveRelearner_Scene", :pbDrawMoveList) do |scene, _r, _a|
  PokeAccess::SkyEggMove.detail(scene)
end
