# Opalo gym (map 46): "maquinaria" and "palancas" toggle switches with no feedback, opening solid
# invisible barriers (same family as Z's ship). A :state puzzle so each activation is announced; no
# solved/hint because the exact win condition is not verified in-game yet. Switches read from the events.
PokeAccess::Game.define("opalo") do
  puzzle(46,
    :kind => :state,
    :watch => [
      { :switch => 174, :label => :op_machine, :on => :op_on, :off => :op_off },
      { :switch => 175, :label => :op_lever1,  :on => :op_on, :off => :op_off },
      { :switch => 177, :label => :op_lever2,  :on => :op_on, :off => :op_off }
    ],
    # The lever-toggled barriers use the steam sprite "Humo" (same family as Z's ship); sound them.
    :obstacles => [{ :match => /humo/i, :kind => :wall }])
end
