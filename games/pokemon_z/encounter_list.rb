# Pokemon Z's DexNav encounter panel (EncounterListUI): shows the current map's wild species as icons with
# no readable text (the species name join is commented out in the game). It is a static panel (no cursor),
# closed with C/B. getEncData fills @encarray with the sorted species (or the sentinel [7] when the map has
# no encounters), so read the zone and species list right after it runs. Z uses EncounterListUI, not the
# Sky/Relict EncounterList_Scene the core reader hooks, hence a game-specific reader. Guarded: no-op where absent.
PokeAccess::Game.define("pokemon_z") do
  after("EncounterListUI", :getEncData) do |scene, _r, _a|
    enc = PokeAccess.ivar(scene, :@encarray)
    loc = ($game_map.name rescue nil).to_s
    if !enc.is_a?(Array) || enc == [7] || enc.empty?
      PokeAccess.speak(PokeAccess::I18n.t(:enc_none, :loc => loc), true)
    else
      entries = enc.map do |sp|
        nm = (PBSpecies.getName(sp) rescue (PokeAccess::Data.species_name(sp) || sp.to_s))
        st = ($Trainer && $Trainer.hasOwned?(sp) rescue false) ? :dex_caught :
             (($Trainer && $Trainer.hasSeen?(sp) rescue false) ? :dex_seen : :dex_unknown)
        [nm, st]
      end
      PokeAccess.speak(PokeAccess::EncounterList.summary(loc, entries), true)
    end
  end
end
