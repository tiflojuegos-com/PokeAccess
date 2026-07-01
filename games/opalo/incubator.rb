# Opalo egg incubator (Kyu's plugin, class Incubadora): the same 6-slot graphic grid as the core Hatcher,
# with @index over $PokemonGlobal.eggs and egg.eggsteps for the hatch hint. refresh runs on open and after
# every cursor move, so reuse the core Incubator reader, deduped by slot. The class is Incubadora here,
# not Hatcher, so the core's own hooks never match -- this adds the equivalent hook for Opalo.
PokeAccess::Game.define("opalo") do
  after("Incubadora", :refresh) { |scene, _result, _args| PokeAccess::Incubator.announce(scene) }
end
