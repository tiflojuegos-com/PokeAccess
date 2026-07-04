# announce_target (gen-6 double battles): while choosing a move's target, the highlighted battler is read
# as name + side (your pokemon / ally / foe). The side is relative to the battler that is CHOOSING, not to
# slot 0: in gen-6 the player controls slots 0 and 2, and when slot 2 chooses a UserOrPartner move it can
# auto-target itself (index 2) or its partner (index 0). Labelling by a hardcoded slot 0 would then call the
# chooser "ally" and its partner "your pokemon". The chooser is recovered from the fight window whose battler
# pbChooseTarget set (cw.battler). Stubs supply only what the reader touches: a battler (name/pokemon/index),
# a fight window exposing that battler, and a scene holding @battle (doublebattle + battlers) and @sprites.

class TargetBattler
  attr_accessor :name, :pokemon, :index

  # Builds a battler stub at a global battler index. pokemon truthy = an occupied slot (named), nil = empty.
  def initialize(name, index, pokemon = :mon)
    @name = name; @index = index; @pokemon = pokemon
  end
end

class TargetFightWindow
  attr_accessor :battler

  # The gen-6 FightMenuDisplay stand-in: pbChooseTarget assigns the choosing battler here (cw.battler=).
  def initialize(battler); @battler = battler; end
end

class TargetScene
  # A gen-6 PokeBattle_Scene stand-in: holds @battle (doublebattle + battlers) and @sprites (fightwindow).
  # param chooser the battler placed on the fight window, or nil to leave the window without one
  def initialize(battlers, chooser)
    @battle = TargetBattle.new(battlers)
    @sprites = {}
    @sprites["fightwindow"] = TargetFightWindow.new(chooser) if chooser
  end
end

class TargetBattle
  attr_accessor :battlers

  # A double battle stub over a battlers array (indices 0/2 = player side, 1/3 = foe side).
  def initialize(battlers); @battlers = battlers; end

  # Every announce_target guard requires a double battle.
  def doublebattle; true; end
end

# Four battlers: player slots 0 and 2, foe slots 1 and 3.
def target_field
  [TargetBattler.new("Bulba", 0), TargetBattler.new("Rattata", 1),
   TargetBattler.new("Char", 2), TargetBattler.new("Pidgey", 3)]
end

Suite.define("battle: slot-2 chooser auto-targeting itself reads 'your pokemon', not 'ally'") do
  field = target_field
  scene = TargetScene.new(field, field[2])
  PokeAccess::Battle.announce_target(scene, -1)
  PokeAccess::Battle.announce_target(scene, 2)
  spoke "the chooser at index 2 names itself", /Char/
  spoke "index 2 as the chooser is 'your pokemon'",
        /#{Regexp.escape(PokeAccess::I18n.t(:bt_target_self))}/
  not_spoke "the chooser is not mislabelled as an ally",
            /#{Regexp.escape(PokeAccess::I18n.t(:bt_target_ally))}/
end

Suite.define("battle: slot-2 chooser targeting the partner at slot 0 reads 'ally', not 'your pokemon'") do
  field = target_field
  scene = TargetScene.new(field, field[2])
  PokeAccess::Battle.announce_target(scene, -1)
  PokeAccess::Battle.announce_target(scene, 0)
  spoke "the partner at index 0 is named", /Bulba/
  spoke "index 0 (the partner) is an ally",
        /#{Regexp.escape(PokeAccess::I18n.t(:bt_target_ally))}/
  not_spoke "the partner is not mislabelled as the user's own pokemon",
            /#{Regexp.escape(PokeAccess::I18n.t(:bt_target_self))}/
end

Suite.define("battle: the classic slot-0 chooser still labels self and ally correctly") do
  field = target_field
  scene = TargetScene.new(field, field[0])
  PokeAccess::Battle.announce_target(scene, -1)
  PokeAccess::Battle.announce_target(scene, 0)
  spoke "index 0 as the chooser is 'your pokemon'",
        /#{Regexp.escape(PokeAccess::I18n.t(:bt_target_self))}/
  PokeAccess::Battle.announce_target(scene, -1)
  PokeAccess::Battle.announce_target(scene, 2)
  spoke "index 2 (the partner) is an ally",
        /#{Regexp.escape(PokeAccess::I18n.t(:bt_target_ally))}/
end

Suite.define("battle: a foe slot is always the foe side regardless of the chooser") do
  field = target_field
  scene = TargetScene.new(field, field[2])
  PokeAccess::Battle.announce_target(scene, -1)
  PokeAccess::Battle.announce_target(scene, 1)
  spoke "an odd index is the foe side", /#{Regexp.escape(PokeAccess::I18n.t(:bt_target_foe))}/
  not_spoke "a foe is never self", /#{Regexp.escape(PokeAccess::I18n.t(:bt_target_self))}/
  not_spoke "a foe is never an ally", /#{Regexp.escape(PokeAccess::I18n.t(:bt_target_ally))}/
end

Suite.define("battle: with no fight window the reader falls back to the slot-0 assumption") do
  field = target_field
  scene = TargetScene.new(field, nil)
  PokeAccess::Battle.announce_target(scene, -1)
  PokeAccess::Battle.announce_target(scene, 0)
  spoke "index 0 defaults to self when the chooser cannot be read",
        /#{Regexp.escape(PokeAccess::I18n.t(:bt_target_self))}/
  PokeAccess::Battle.announce_target(scene, -1)
  PokeAccess::Battle.announce_target(scene, 2)
  spoke "index 2 defaults to ally when the chooser cannot be read",
        /#{Regexp.escape(PokeAccess::I18n.t(:bt_target_ally))}/
end

Suite.define("battle: an empty highlighted slot reads the empty-slot label") do
  field = [TargetBattler.new("Bulba", 0), TargetBattler.new("Rattata", 1),
           TargetBattler.new("", 2, nil), TargetBattler.new("Pidgey", 3)]
  scene = TargetScene.new(field, field[0])
  PokeAccess::Battle.announce_target(scene, -1)
  PokeAccess::Battle.announce_target(scene, 2)
  spoke "an unoccupied target slot is announced as empty",
        /#{Regexp.escape(PokeAccess::I18n.t(:bt_empty_slot))}/
end
