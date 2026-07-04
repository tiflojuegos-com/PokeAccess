# Z's recipe/infographic viewer (ItemInfog_Scene, the crafting "guia"): a sprite-based list of
# infographics (@lista_infog, each entry [name, image]); pbRedrawMenu(index, _) redraws the focused entry.
# Reads the focused entry's name as you navigate. The infographic shown on confirm is a full-screen IMAGE,
# so its content would need a per-image transcription, like the alchemy book.
PokeAccess::Game.define("pokemon_z") do
  after("ItemInfog_Scene", :pbRedrawMenu) do |scene, _r, args|
    lista = scene.instance_variable_get(:@lista_infog)
    idx = args[0]
    if lista.is_a?(Array) && idx && lista[idx]
      nm = (lista[idx][0] rescue nil)
      PokeAccess.speak_clean(nm.to_s, true) if nm && !nm.to_s.empty?
    end
  end
end
