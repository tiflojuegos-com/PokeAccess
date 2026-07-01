# Armonia field DexNav (DexNav, opened from the pause menu). A blocking UI navigated by zone with left/
# right; loadCurrentPage redraws on open and on every zone change, and its species are shown only as
# icons. Reads the zone name (land/surf/fishing) and the species found in it.
PokeAccess::Game.define("armonia") do
  after("DexNav", :loadCurrentPage) do |scene, _result, _args|
    zone = (scene.instance_variable_get(:@visibleZones)[scene.instance_variable_get(:@index)] rescue nil)
    zname = { "dexnavtierra" => "Hierba", "dexnavsurf" => "Surf", "dexnavrio" => "Pesca" }[zone && zone[1]] || "Zona"
    species = (scene.instance_variable_get(:@encounterArray) || []).map { |s| (PBSpecies.getName(s) rescue s.to_s) }
    body = species.empty? ? "sin especies detectadas" : "#{species.length} especies: #{species.join(", ")}"
    PokeAccess.speak("#{zname}, #{body}", true)
  end
end
