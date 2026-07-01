# Data resolution on the gen-6 harness: the PB* provider is the active one and each resolver maps an
# id to its name or basic field, with move power/accuracy coming from PBMoveData (not PBMove). This is the
# engine-agnostic contract the shared readers rely on; the modern equivalent lives in provider_modern_gd_spec.
Suite.define("data: gen-6 provider resolves ids") do
  eq "gen-6 provider is active", PokeAccess::Data.active, PokeAccess::DataG6
  eq "move_name", PokeAccess::Data.move_name(7), "Mov7"
  eq "move_power via PBMoveData", PokeAccess::Data.move_power(7), 47
  eq "move_accuracy", PokeAccess::Data.move_accuracy(7), 100
  eq "type_name", PokeAccess::Data.type_name(2), "Tipo2"
  eq "item_name", PokeAccess::Data.item_name(25), "Repel"
  eq "species_name", PokeAccess::Data.species_name(3), "Especie3"
  eq "species_entry", PokeAccess::Data.species_entry(3), ["Especie3", "msg3", "msg3"]
  eq "nature_name", PokeAccess::Data.nature_name(1), "Naturaleza1"
  eq "stat_name", PokeAccess::Data.stat_name(4), "Estadistica4"
  eq "item_id symbol to id", PokeAccess::Data.item_id("REPEL"), [25, "Repel"]

  pkt = Object.new
  def pkt.type1; 1; end
  def pkt.type2; 2; end
  eq "pokemon_types gen-6", PokeAccess::Data.pokemon_types(pkt), ["Tipo1", "Tipo2"]
end

# The toolkit boots cleanly under the harness and exposes its core submodules; a regression here means a
# manifest entry or a require chain broke before any reader could run.
Suite.define("data: core submodules present after load") do
  %w[Config Hooks Keys Info Menus Battle Party Summary Locator Pathfinder Spatial
     ConfigMenu Settings Audio3D Pokedex Tags Appearance Data].each do |m|
    truthy "submodule #{m}", (PokeAccess.const_defined?(m.to_sym) rescue false)
  end
end
