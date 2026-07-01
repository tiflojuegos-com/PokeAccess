# announce_hp_change: when a battler's HP changes it is spoken once, as a loss or a gain. The player's own
# Pokemon (even index) reads its exact HP; a foe (odd index) reads a percentage, since the exact value is
# hidden in battle. No change and a nil old value speak nothing. A small battler stub supplies the four
# fields the helper reads (hp / totalhp / index / name); the spoken fragments are matched through I18n.
class TestBattler
  attr_accessor :hp, :totalhp, :index, :name

  # Builds a battler stub. index even = player side (exact HP), odd = foe side (percentage).
  def initialize(name, hp, totalhp, index)
    @name = name; @hp = hp; @totalhp = totalhp; @index = index
  end
end

Suite.define("battle: HP loss on the player's Pokemon reads exact HP") do
  pkmn = TestBattler.new("Bulba", 20, 44, 0)
  PokeAccess::Battle.announce_hp_change(pkmn, 30)
  spoke_once "the change is announced once", /Bulba/
  spoke "spoken as a loss", /#{Regexp.escape(PokeAccess::I18n.t(:bt_lose))}/
  spoke "reads the exact remaining HP", /#{Regexp.escape(PokeAccess::I18n.t(:bt_hp_exact, :hp => 20, :tot => 44))}/
end

Suite.define("battle: HP gain on a foe reads a percentage") do
  foe = TestBattler.new("Rattata", 50, 100, 1)
  PokeAccess::Battle.announce_hp_change(foe, 20)
  spoke "spoken as a gain", /#{Regexp.escape(PokeAccess::I18n.t(:bt_gain))}/
  spoke "reads a percentage, not the exact value", /#{Regexp.escape(PokeAccess::I18n.t(:bt_hp_pct, :n => 50))}/
  not_spoke "does not leak the exact foe HP", /#{Regexp.escape(PokeAccess::I18n.t(:bt_hp_exact, :hp => 50, :tot => 100))}/
end

Suite.define("battle: no HP change and nil old value say nothing") do
  pkmn = TestBattler.new("Char", 40, 40, 0)
  PokeAccess::Battle.announce_hp_change(pkmn, 40)
  silent "an unchanged HP says nothing"
  PokeAccess::Battle.announce_hp_change(pkmn, nil)
  silent "a nil old value says nothing"
end
