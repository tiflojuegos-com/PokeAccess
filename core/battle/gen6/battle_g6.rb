# Gen-6 battle scene reader (PokeBattle_Scene + CommandMenuDisplay/FightMenuDisplay): battle messages,
# command/move menus, target selection, mega flag, level-up and damage. Binds only where the gen-6 scene
# classes exist; the modern battle reader is core/battle/v21/battle_v21.rb. All the spoken logic lives in the
# shared PokeAccess::Battle module (core/battle/battle.rb); these are just the gen-6 bindings.

# Battle messages (also captures the battle for the hp/field keys).
PokeAccess::Hooks.before_hook("PokeBattle_Scene", :pbDisplayMessage) do |scene, args|
  PokeAccess::Battle.set_battle(scene.instance_variable_get(:@battle))
  PokeAccess.speak_clean(args[0], false)
end

# Paused battle messages (exp gained, level up): routed via pbDisplayPaused, a different method than
# pbDisplayMessage, so it needs its own hook.
PokeAccess::Hooks.before_hook("PokeBattle_Scene", :pbDisplayPausedMessage) do |_s, args|
  PokeAccess.speak_clean(args[0], false)
end

# Move-target selection in doubles: pbChooseTarget highlights the focused battler each frame via
# pbUpdateSelected(index); read whoever is under the cursor as it moves. hook_container because its original
# drives the command/fight display's own hooked index setters internally; guarding it would mute those readers.
PokeAccess::Hooks.after_hook("PokeBattle_Scene", :pbUpdateSelected, :hook_container => true) do |scene, _r, args|
  PokeAccess::Battle.announce_target(scene, args[0])
end

# Battle prompts with options (yes/no like "give a nickname?", fainted-pokemon choices): the question
# text is set straight on the message window, not via pbDisplayMessage, so it is read here; the Si/No
# options are a Window_CommandPokemon read by the generic hook.
PokeAccess::Hooks.before_hook("PokeBattle_Scene", :pbShowCommands) do |_s, args|
  PokeAccess.speak_clean(args[0], false)
end

# Command menu (also resets the info key to read the foe here). The first read after the menu opens is
# queued so it does not cut the hp/turn lines; navigation interrupts.
PokeAccess::Hooks.after_hook("CommandMenuDisplay", :index=) do |disp, _r, args|
  PokeAccess::Info.set_info(:battle_foe, nil)
  cmds = disp.instance_variable_get(:@window).instance_variable_get(:@commands)
  v = args[0]
  opening = PokeAccess::Battle.cmd_opening_consume
  PokeAccess.speak_clean(cmds[v], !opening) if cmds && cmds[v].is_a?(String)
end

# The command menu opens at the start of the command phase via pbCommandMenu/Ex (which sets the initial
# cursor with cw.index=), so flag the next index= read as an open.
["PokeBattle_Scene"].each do |cn|
  ["pbCommandMenu", "pbCommandMenuEx"].each do |m|
    PokeAccess::Hooks.before_hook(cn, m) { |_s, _args| PokeAccess::Battle.cmd_opening! }
  end
end

# Move selection: read only when the focused move actually changes, so pressing a direction toward an empty
# slot (the move does not move) is not mistaken for a re-read. An empty/absent slot passes key nil, which
# Cursor treats as unchanged, so it neither speaks nor records -- returning to the same real move still reads.
PokeAccess::Hooks.after_hook("FightMenuDisplay", :setIndex) do |disp, _r, _a|
  b = disp.instance_variable_get(:@battler)
  idx = disp.instance_variable_get(:@index)
  ok = b && b.moves[idx] && b.moves[idx].id != 0
  PokeAccess::Cursor.on_change(disp, :fight_move, ok ? idx : nil) do
    m = b.moves[idx]
    t = m.name.to_s
    t += ". " + PokeAccess::I18n.t(:mv_pp, :pp => m.pp, :tot => m.totalpp) if m.respond_to?(:pp)
    PokeAccess.speak_clean(t, true)
    PokeAccess::Info.set_info(:move, m)
  end
end

# Reset the dedup when the menu is set up for a battler, so the move is read on open.
PokeAccess::Hooks.after_hook("FightMenuDisplay", :battler=) do |disp, _r, _a|
  PokeAccess::Cursor.reset(disp, :fight_move)
end

# Mega button (gen-6, one-way): announce when it flips to registered.
PokeAccess::Hooks.after_hook("FightMenuDisplay", :megaButton=) do |disp, _r, args|
  v = args[0]
  k = PokeAccess::Battle.mega_key(disp.instance_variable_get(:@access_mega), v)
  disp.instance_variable_set(:@access_mega, v) if v == 1 || v == 2
  PokeAccess.speak(PokeAccess::I18n.t(k), true) if k
end

# Level-up stat gains (gen-6): the panel is graphic-only. Old-stat arg order here is hp,atk,def,speed,
# spatk,spdef, so speed is a[5] and spatk/spdef are a[6]/a[7].
PokeAccess::Hooks.after_hook("PokeBattle_Scene", :pbLevelUp) do |_s, _r, a|
  PokeAccess.speak(PokeAccess::Battle.levelup_text(a[0], a[2], a[3], a[4], a[6], a[7], a[5]), false)
end

# Damage number (not a message, so it is read here).
PokeAccess::Hooks.after_hook("PokeBattle_Scene", :pbHPChanged) do |_s, _r, args|
  PokeAccess::Battle.announce_hp_change(args[0], args[1])
end

# Silence the map sonar during gen-6 battles. gen-6 never sets $game_temp.in_battle and runs the whole
# fight inside Scene_Map, so the scene-change / in_battle checks never fire for wild encounters (trainer
# fights happened to be covered by the running interpreter, but wild ones are not). pbBattleAnimation is the
# top-level function that WRAPS the entire battle (both wild and trainer) in its block, so an around wrap on
# it marks the in-battle flag for the whole fight and clears it on the way out, whatever raised. No-op where
# the function is absent (modern engines already silence via the scene change).
PokeAccess::Hooks.wrap_kernel("pbBattleAnimation", "hook_battle_sonar", :around) do |args, call_next|
  PokeAccess::Battle.battle_started
  begin
    call_next.call
  ensure
    PokeAccess::Battle.battle_ended
  end
end
