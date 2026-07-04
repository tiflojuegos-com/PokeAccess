module PokeAccess
  # Reminiscencia picks up floor items through the BOTW-like "FastItemGet" plugin, whose pbItemBall plays a
  # silent animated sprite (itemAnim) with NO message on success -- so nothing reads it, unlike chests/NPC
  # gifts which use pbMessage. We voice it ourselves from the pbItemBall arguments (the plugin never does).
  module ReminItemGet
    # The spoken "found X" line for a pbItemBall call, or nil. item may be an id, a name string or a symbol.
    def self.say(item, quantity)
      return if item.nil?
      qty = (quantity || 1).to_i
      name = if item.is_a?(String)
               item
             else
               qty > 1 ? PokeAccess::Data.item_name_plural(item) : PokeAccess::Data.item_name(item)
             end
      return if name.nil? || name.to_s.empty?
      t = (qty > 1) ? PokeAccess::I18n.t(:ri_found_n, :n => qty, :name => name) :
                      PokeAccess::I18n.t(:ri_found, :name => name)
      PokeAccess.speak_clean(t, false)
    rescue StandardError
      nil
    end
  end
end

# pbItemBall is the floor-item entry point; the FastItemGet plugin's version shows only a silent sprite, so
# voice the pickup before it runs. No-op where pbItemBall is absent.
PokeAccess::Hooks.wrap_kernel("pbItemBall", "hook_remi_itemget", :before) do |args, _r|
  PokeAccess::ReminItemGet.say(args[0], args[1])
end
