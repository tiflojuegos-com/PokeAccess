# Relict picks up floor items through the QuickPickup addon (FAST_PICK_ITEM_ACTIVE = 1 by default), whose
# pbItemBall plays a silent BOTW-style animation (itemAnim) with NO message on success -- so nothing reads
# it, unlike chests/NPC gifts which use pbMessage. We voice it ourselves from the pbItemBall arguments, the
# same gap fixed for Reminiscencia but with the modern GameData item API instead of gen-6 PBItems.
module PokeAccess
  module RelictItemGet
    # The spoken "found X" line for a pbItemBall call, or nil. item is an id/symbol/GameData::Item.
    def self.say(item, quantity)
      return if item.nil?
      qty = (quantity || 1).to_i
      data = (GameData::Item.get(item) rescue nil)
      return if data.nil?
      name = (qty > 1 ? (data.portion_name_plural rescue nil) : nil) || (data.portion_name rescue nil) ||
             (data.name rescue nil)
      return if name.nil? || name.to_s.empty?
      t = (qty > 1) ? PokeAccess::I18n.t(:ri_found_n, :n => qty, :name => name) :
                      PokeAccess::I18n.t(:ri_found, :name => name)
      PokeAccess.speak(PokeAccess.clean(t), false)
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("relict") do
  kernel("pbItemBall", :before) do |args, _r|
    PokeAccess::RelictItemGet.say(args[0], args[1])
  end
end
