# Data resolution on the modern (GameData) harness: DataV21 is the active provider and resolves names and
# rich fields through GameData::*. Runs only in the gamedata engine pass (the _gd suffix), where GameData is
# present; on the gen-6 harness GameData is absent so the gen-6 provider is the one selected (see
# provider_gen6_spec).
Suite.define("data: modern provider resolves ids") do
  d = PokeAccess::Data
  eq "modern provider is active", d.active, PokeAccess::DataV21
  eq "move_name", d.move_name(7), "Move7"
  eq "move_power", d.move_power(7), 40
  eq "move_accuracy", d.move_accuracy(7), 100
  eq "move_type_name", d.move_type_name(7), "TypeTYPE1"
  eq "move_description", d.move_description(7), "desc7"
  eq "type_name", d.type_name(:FIRE), "TypeFIRE"
  eq "item_name", d.item_name(:POTION), "ItemPOTION"
  eq "item_description", d.item_description(:POTION), "idescPOTION"
  eq "species_name", d.species_name(:PIKACHU), "SpeciesPIKACHU"
  eq "species_entry", d.species_entry(:PIKACHU), ["SpeciesPIKACHU", "catPIKACHU", "dexPIKACHU"]
  eq "ability_name", d.ability_name(:STATIC), "AbilitySTATIC"
  eq "nature_name", d.nature_name(:BOLD), "NatureBOLD"
  eq "status_name", d.status_name(:BURN), "StatusBURN"
  eq "stat_name", d.stat_name(:ATTACK), "StatATTACK"
  eq "item_id symbol", d.item_id("POTION"), [:POTION, "ItemPOTION"]

  pk = Object.new
  def pk.types; [:FIRE, :FLYING]; end
  eq "pokemon_types", d.pokemon_types(pk), ["TypeFIRE", "TypeFLYING"]
end
