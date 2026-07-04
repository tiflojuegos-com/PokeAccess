# entry_number is the dex number the v21 pokedex entry reader speaks for the focused species. The entry
# screen stores a raw 1-based list position in :number and, for regions listed in DEXES_WITH_OFFSETS, marks
# the entry with :shift and displays number - 1. The reader must mirror that: with :shift the spoken number
# is one lower than the stored one, so it matches the digits shown on screen. A fake scene supplies the two
# ivars the reader reads (@dexlist / @index).
Suite.define("battle: pokedex entry_number matches the shown number without an offset") do
  scene = Object.new
  scene.instance_variable_set(:@dexlist, [{ :species => :BULBASAUR, :number => 4, :shift => false }])
  scene.instance_variable_set(:@index, 0)
  eq "the raw number is spoken when the dex has no offset", PokeAccess::PokedexInfoV21.entry_number(scene), 4
end

Suite.define("battle: pokedex entry_number applies the :shift offset like the screen") do
  scene = Object.new
  scene.instance_variable_set(:@dexlist, [{ :species => :BULBASAUR, :number => 4, :shift => true }])
  scene.instance_variable_set(:@index, 0)
  eq "an offset dex speaks one less than the stored number", PokeAccess::PokedexInfoV21.entry_number(scene), 3
end

# The screen only applies the shift when number > 0 (0 renders as "???"), so an unnumbered entry stays nil
# whether or not :shift is set, and a missing dexlist yields nil rather than a bogus number.
Suite.define("battle: pokedex entry_number stays nil for an unnumbered entry") do
  scene = Object.new
  scene.instance_variable_set(:@dexlist, [{ :species => :MEW, :number => 0, :shift => true }])
  scene.instance_variable_set(:@index, 0)
  falsy "a zero number is not spoken even with an offset flag", PokeAccess::PokedexInfoV21.entry_number(scene)

  bare = Object.new
  falsy "a scene without a dexlist yields no number", PokeAccess::PokedexInfoV21.entry_number(bare)
end
