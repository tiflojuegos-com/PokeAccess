# Regression: the map sonar must go quiet during a gen-6 wild battle. gen-6 never sets $game_temp.in_battle
# and runs the fight inside Scene_Map, so the silence is driven by a Battle.in_battle? flag set from the
# battle scene's start/end, which Spatial.busy? consults. (busy? has other branches the stub can trip, so
# this asserts the flag and that busy? becomes true specifically because of it.)
Suite.define("battle: sonar silenced while in battle (gen-6 wild)") do
  PokeAccess::Battle.battle_ended
  falsy "flag clear at rest", PokeAccess::Battle.in_battle?
  PokeAccess::Battle.battle_started
  truthy "flag set once a battle starts", PokeAccess::Battle.in_battle?
  truthy "busy is true while the in-battle flag is set", PokeAccess::Spatial.busy?
  PokeAccess::Battle.battle_ended
  falsy "flag clear after the battle ends", PokeAccess::Battle.in_battle?
end

# clear_battle runs every map frame (including during a gen-6 fight, which runs inside Scene_Map), so it
# must NOT lower the in-battle flag -- otherwise the flag set by pbBattleAnimation would be erased one frame
# later and the sonar would never stay silent during a wild battle. The flag is owned only by battle_ended.
Suite.define("battle: clear_battle does NOT lower the in-battle flag") do
  PokeAccess::Battle.battle_started
  PokeAccess::Battle.clear_battle
  truthy "flag survives a per-frame clear_battle", PokeAccess::Battle.in_battle?
  PokeAccess::Battle.battle_ended
  falsy "only battle_ended clears it", PokeAccess::Battle.in_battle?
end
