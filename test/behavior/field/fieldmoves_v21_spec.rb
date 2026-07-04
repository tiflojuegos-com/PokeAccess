# Regression (reentrancy guard must not silence in-loop navigation): the v21 field-move menu
# (SelectMoveMenu_Scene) reads the focused option from an after-hook on refresh_buttons, which the engine
# calls on each cursor move INSIDE the pbShowCommands modal loop; pbShowCommands has a before-hook that
# resets the dedup and reads the first option. When the guard was pushed on the before path, :pbShowCommands
# sat on the active stack for the whole loop, so every nested refresh_buttons (a different method) was
# skipped and the menu went mute the moment you moved -- only the first option (read by the before body)
# was heard. The guard now lives on the after path only, so each option is read as the cursor visits it.
Suite.define("field moves v21: navigating the menu reads each focused option") do
  cmds = [[:CUT, "Corte", 0, 0], [:SURF, "Surf", 0, 1], [:FLY, "Vuelo", 0, 2]]
  scene = SelectMoveMenu_Scene.new(cmds, [1, 2])
  SpeakCapture.clear
  scene.pbShowCommands
  spoke "the option focused mid-loop is read (Surf)", /Surf/
  spoke "the next option focused mid-loop is read (Vuelo)", /Vuelo/
end
