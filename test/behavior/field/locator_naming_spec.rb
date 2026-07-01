# Regression + coverage: target_name classifies map events by data shape, not by name. A battle trainer's
# two same-sprite pages gated by a self-switch look like a lever, so trainers must NOT read as levers
# (the lever check runs after Trainer/PC/exit, and a battle script disqualifies a lever).
Suite.define("locator: target_name classifies events by shape") do
  World.clear_events
  lever = World.event(:kind => :lever, :id => 1)
  trainer = World.event(:kind => :trainer, :id => 2, :name => "Trainer(5)")
  $game_map.map_id = 900

  match "a two-pose switch-gated event reads as a lever", PokeAccess::Locator.target_name(lever), /Palanca/i

  name = PokeAccess::Locator.target_name(trainer)
  eq "a battle trainer is NOT read as a lever", (name.to_s =~ /Palanca/i ? true : false), false

  door = World.event(:kind => :door, :id => 3)
  truthy "a touch-transfer tile is a transfer event", (PokeAccess::Locator.transfer_event?(door) rescue false)
end

# The locator reads the item an item-ball event gives, by parsing its pbItemBall(...) script command, so a
# pickup announces what it contains rather than a generic "item ball".
Suite.define("locator: item_name parses the pbItemBall script") do
  cmd = Struct.new(:code, :parameters)
  ev = Struct.new(:l) do
    def instance_variable_get(s); s == :@list ? l : nil; end
  end.new([cmd.new(355, ["pbItemBall(PBItems::REPEL)"])])
  eq "reads the item out of the ball script", PokeAccess::Locator.item_name(ev), "Repel"
end

# Field-move obstacles: both gen-6 bare sprite names AND modern names resolve to a label, with no false
# positive on a name that merely contains an obstacle word ("Rockstar").
Suite.define("locator: field-move obstacle labelling") do
  fme = Struct.new(:name)
  eq "gen-6 Rock", PokeAccess::Locator.fieldmove_label(fme.new("Rock")), :loc_rock_smash
  eq "gen-6 Tree", PokeAccess::Locator.fieldmove_label(fme.new("Tree")), :loc_cut_tree
  eq "gen-6 Boulder", PokeAccess::Locator.fieldmove_label(fme.new("Boulder")), :loc_strength_boulder
  eq "modern cuttree", PokeAccess::Locator.fieldmove_label(fme.new("cuttree")), :loc_cut_tree
  truthy "no false positive", PokeAccess::Locator.fieldmove_label(fme.new("Rockstar")).nil?
end

# The on-screen-keyboard scene the naming reader inspects: it exposes the character rows via a class
# variable @@Characters (upper / lower), exactly as the gen-6 Window_TextEntry does.
class FakeNamingScene
  @@Characters = [[("ABCDEFGHIJ ,.").scan(/./), "UPPER"], [("abcdefghij ,.").scan(/./), "lower"]]
end

# Cursor-mode naming: focus_text maps a grid position to its character (upper/lower by mode) or to the
# space/control label, so the on-screen-keyboard reader voices what the cursor is on.
Suite.define("locator: cursor-mode naming grid") do
  fn = FakeNamingScene.new
  eq "grid character", PokeAccess::CursorNaming.focus_text(fn, 0, 0), "A"
  eq "lowercase by mode", PokeAccess::CursorNaming.focus_text(fn, 1, 2), "c"
  eq "gap reads as space", PokeAccess::CursorNaming.focus_text(fn, 0, 10), PokeAccess::I18n.t(:key_space)
  eq "OK control", PokeAccess::CursorNaming.focus_text(fn, 0, -1), PokeAccess::I18n.t(:nm_ok)
  eq "uppercase control", PokeAccess::CursorNaming.focus_text(fn, 0, -6), PokeAccess::I18n.t(:nm_upper)
end
