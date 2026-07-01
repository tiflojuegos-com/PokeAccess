# Armonia starter selection (shiney570's PokemonStarterSelection): a custom sprite picker that replaces the
# standard starter menu. gettinginput runs every frame and moves @select (1..3) over three balls; the focused
# starter is @pokemon (a PokeBattle_Pokemon) and its name/types are drawn to a bitmap, so nothing is spoken.
# Hook gettinginput, dedup by @select, and read the focused starter's name and type(s). The confirm prompt
# (pbConfirmMessage) is already spoken by the message reader.
PokeAccess::Game.define("armonia") do
  after("PokemonStarterSelection", :gettinginput) do |scene, _result, _args|
    sel = (scene.instance_variable_get(:@select) rescue nil)
    next if sel.nil? || sel == scene.instance_variable_get(:@access_starter_sel)
    scene.instance_variable_set(:@access_starter_sel, sel)
    pkmn = (scene.instance_variable_get(:@pokemon) rescue nil)
    next unless pkmn
    name = (pkmn.name rescue nil)
    next if !name || name.to_s.empty?
    types = (PokeAccess::Data.pokemon_types(pkmn) rescue [])
    txt = types.empty? ? name.to_s : "#{name}, #{types.join('/')}"
    PokeAccess.speak(PokeAccess.clean(txt), true)
  end
end
