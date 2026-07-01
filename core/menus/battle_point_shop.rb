module PokeAccess
  # Battle Point shop (Window_BattlePointShop), a Window_DrawableCommand whose entries are item ids in @stock
  # with names/prices via its @adapter -- the generic reader would speak the raw id symbol. A profile that
  # ships this plugin opts in with BattlePointShop.define(game).
  module BattlePointShop
    # Registers the Window_BattlePointShop reader for a game profile: focused item's name and BP price, or
    # the cancel label on the last row.
    def self.define(game)
      PokeAccess::Game.define(game) do
        screen_reader("Window_BattlePointShop") do |win, i|
          stock = win.instance_variable_get(:@stock)
          next PokeAccess::I18n.t(:pc_cancel) if stock.is_a?(Array) && i >= stock.length
          next nil unless stock.is_a?(Array) && stock[i]
          item = stock[i]
          ad = win.instance_variable_get(:@adapter)
          name = (ad.getDisplayName(item) rescue nil) if ad
          name = (PokeAccess::Data.item_name(item) || item.to_s) if name.nil? || name.to_s.empty?
          price = (ad.getDisplayPrice(item) rescue nil) if ad
          (price && !price.to_s.empty?) ? "#{name}, #{price}" : name
        end
      end
    end
  end
end
