module PokeAccess
  # Awakening's item crafting (ItemCraft_Scene in "Crafteo"): left/right pick the recipe, up/down the
  # amount, in a blocking loop whose cursor is a LOCAL variable -- but pbRedrawItem(index, volume) is called
  # on every change, so that is the read point. @stock[index] is [result_item, [ingredient, qty, ...]];
  # speak the result item and the amount (deduped so an unchanged redraw stays silent).
  module AwakeningCraft
    @last = nil

    # Resets the dedup when the crafting screen opens.
    def self.reset; @last = nil; end

    # Reads the focused recipe (result item + amount) from a pbRedrawItem call.
    def self.say(scene, index, volume)
      stock = (scene.instance_variable_get(:@stock) rescue nil)
      return unless stock.is_a?(Array) && index && index >= 0 && index < stock.length
      item = (stock[index][0] rescue nil)
      return if item.nil?
      vol = (volume || 1).to_i
      key = [index, vol]
      return if key == @last
      @last = key
      name = (vol > 1 ? (PBItems.getNamePlural(item) rescue nil) : nil) || (PBItems.getName(item) rescue nil)
      return if name.nil? || name.to_s.empty?
      t = (vol > 1) ? PokeAccess::I18n.t(:aw_craft_n, :n => vol, :name => name) :
                      PokeAccess::I18n.t(:aw_craft, :name => name)
      PokeAccess.speak(PokeAccess.clean(t), true)
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("awakening") do
  before("ItemCraft_Scene", :pbCraftItem) do |_s, _a|
    PokeAccess::AwakeningCraft.reset
  end
  after("ItemCraft_Scene", :pbRedrawItem) do |scene, _r, args|
    PokeAccess::AwakeningCraft.say(scene, args[0], args[1])
  end
end
