# Terrain predicates on the modern shape: a tag OBJECT with boolean flags (gen-6's Integer path is covered
# by the ice tests). Each predicate must read the object's flag; number() reads id_number. This is what lets
# the pathfinder treat ice / water / bridge / ledge tiles correctly across both engine shapes.
Suite.define("terrain: modern tag-object flags") do
  modtag = Struct.new(:id_number, :can_surf, :ledge, :ice, :bridge, :waterfall, :can_dive)
  t_ice = modtag.new(12, false, false, true, false, false, false)
  t_water = modtag.new(7, true, false, false, false, false, false)
  truthy "ice? reads the flag and is not surfable",
         PokeAccess::Terrain.ice?(t_ice) == true && PokeAccess::Terrain.surfable?(t_ice) == false
  eq "surfable? reads the flag", PokeAccess::Terrain.surfable?(t_water), true
  eq "number() is id_number", PokeAccess::Terrain.number(t_ice), 12
  truthy "bridge? and ledge? read their flags",
         PokeAccess::Terrain.bridge?(modtag.new(15, false, false, false, true, false, false)) == true &&
         PokeAccess::Terrain.ledge?(modtag.new(1, false, true, false, false, false, false)) == true
end
