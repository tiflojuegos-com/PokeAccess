module PokeAccess
  # Monotype challenge type picker (Monotype Challenge plugin, MonotypeMenu_Scene). A custom
  # sprite list scrolled by @index over @type_list, with a trailing special option (toggle the
  # recommended/other list) at the last index, and no command window. pbRedrawList runs on open
  # and each cursor move, so the focused type (or the special option) is read from there, deduped.
  module AnilMonotype
    # The focused type name, or the special "more types" option at the end of the list.
    def self.text(scene)
      tl  = PokeAccess.ivar(scene, :@type_list)
      idx = PokeAccess.ivar(scene, :@index)
      return nil unless tl.is_a?(Array) && idx
      return PokeAccess::I18n.t(:mono_other) if idx >= tl.length
      ty = tl[idx]
      name = (GameData::Type.get(ty).name rescue (ty.respond_to?(:name) ? ty.name : ty.to_s))
      PokeAccess::I18n.t(:mono_type, :type => name)
    rescue StandardError
      nil
    end

    # Speaks the focused type when it changes; the dedup lives on the scene so it resets on reopen.
    def self.read(scene)
      t = text(scene)
      PokeAccess::Cursor.announce(scene, :mono_type, t, true) { t } unless t.nil?
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("anil") do
  after("MonotypeMenu_Scene", :pbRedrawList) do |scene, _r, _a|
    PokeAccess::AnilMonotype.read(scene)
  end
end
