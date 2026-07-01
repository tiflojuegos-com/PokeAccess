# Battle bag (NewBattleBag, script 232, custom EBS ui; not Window_PokemonBag). Game-prefixed module so this
# Z-specific reader never collides with a core namespace, matching the ZSummary/ZPokedex convention.
module PokeAccess
  module ZBattleBag
    # Speaks the battle bag depending on its state (pocket choice vs item list).
    def self.announce(bag)
      selp = bag.instance_variable_get(:@selPocket)
      if selp == 0
        announce_pockets(bag)
      else
        announce_items(bag)
      end
    rescue StandardError
      nil
    end

    # Speaks the pocket-selection screen entry (pocket, last item or back).
    def self.announce_pockets(bag)
      idx = bag.instance_variable_get(:@index)
      key = "main#{idx}"
      return if key == @key
      @key = key
      labels = (PokeAccess.const_at("NewBattleBag::PocketText") || [])
      txt = case idx
            when 0, 1, 2, 3 then labels[idx].to_s
            when 4
              lu = bag.instance_variable_get(:@lastUsed)
              (lu && lu > 0) ? "Ultimo objeto, #{PBItems.getName(lu)}" : "Ultimo objeto"
            when 5 then "Atras"
            else nil
            end
      PokeAccess.speak(txt, true) if txt && !txt.empty?
    end

    # Speaks the item-list screen entry (item with quantity or back).
    def self.announce_items(bag)
      if bag.instance_variable_get(:@back)
        return if @key == "back"
        @key = "back"
        return PokeAccess.speak("Atras", true)
      end
      item   = bag.instance_variable_get(:@item)
      pocket = bag.instance_variable_get(:@pocket)
      entry  = (pocket && item) ? pocket[item] : nil
      key = "it#{item}"
      return if key == @key
      @key = key
      if entry
        PokeAccess::Info.set_info(:item, entry[0])
        PokeAccess.speak("#{PBItems.getName(entry[0])}, #{entry[1]}", true)
      end
    end
  end
end

PokeAccess::Game.define("pokemon_z") do
  after("NewBattleBag", :update) do |bag, _r, _a|
    PokeAccess::ZBattleBag.announce(bag)
  end
end
