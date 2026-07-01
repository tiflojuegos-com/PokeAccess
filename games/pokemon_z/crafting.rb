# Crafting (ItemCraft_Scene, script 222; mandatory for the story).
# @stock = recipes [result_item, [ingredient, qty, ingredient, qty...]]. Game-prefixed module so this
# Z-specific reader never collides with a core namespace, matching the ZSummary/ZPokedex convention.
module PokeAccess
  module ZCrafting
    # Speaks the recipe detail screen: result, quantity and ingredients have/need.
    def self.announce_detail(scene, index, volume)
      stock = scene.instance_variable_get(:@stock)
      ad    = scene.instance_variable_get(:@adapter)
      return unless stock && stock[index] && ad
      recipe = stock[index]
      name = (ad.getName(recipe[0]) rescue recipe[0].to_s)
      ings = recipe[1] || []
      vol  = (volume || 1)
      parts = []
      ings.each_slice(2) do |item, qty|
        next unless qty
        have  = (ad.getQuantity(item) rescue 0)
        iname = (ad.getName(item) rescue item.to_s)
        parts.push("#{iname} #{have} de #{vol * qty}")
      end
      PokeAccess.speak("#{name}. Cantidad #{vol}. Ingredientes: #{parts.join(', ')}", true)
    rescue StandardError
      nil
    end

    # Speaks the recipe list entry (name and a missing-materials notice).
    def self.announce_list(scene, index)
      stock = scene.instance_variable_get(:@stock)
      ad    = scene.instance_variable_get(:@adapter)
      return unless stock && stock[index] && ad
      return if index == @list_idx
      @list_idx = index
      recipe = stock[index]
      name = (ad.getName(recipe[0]) rescue recipe[0].to_s)
      ings = recipe[1] || []
      can = true
      ings.each_slice(2) do |item, qty|
        can = false if qty && (ad.getQuantity(item) rescue 0) < qty
      end
      PokeAccess.speak("#{name}#{can ? '' : ', te faltan materiales'}", true)
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("pokemon_z") do
  # Recipe list navigation (the list screen was the mute one).
  after("ItemCraft_Scene", :pbRedrawMenu) do |scene, _r, args|
    PokeAccess::ZCrafting.announce_list(scene, args[0])
  end

  # Recipe detail navigation (quantity + ingredients).
  after("ItemCraft_Scene", :refreshNumbers) do |scene, _r, args|
    PokeAccess::ZCrafting.announce_detail(scene, args[0], args[1])
  end
end
