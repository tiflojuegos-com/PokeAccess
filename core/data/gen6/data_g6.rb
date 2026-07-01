module PokeAccess
  # Gen-6 data provider (PB* tables + pbGetMessage): names and move/item fields for the PScreen era. The
  # resolvers stay raw -- PokeAccess::Data wraps every call nil-safe, so a missing datum reads as nil
  # rather than each method repeating a rescue. Registered only on gen-6 (see the guard below).
  module DataG6
    def self.move_name(id);        PBMoves.getName(id); end
    def self.move_power(id);       PBMoveData.new(id).basedamage; end
    def self.move_accuracy(id);    PBMoveData.new(id).accuracy; end
    def self.move_type_name(id);   PBTypes.getName(PBMoveData.new(id).type); end
    def self.move_description(id); pbGetMessage(MessageTypes::MoveDescriptions, id); end
    def self.type_name(id);        PBTypes.getName(id); end
    def self.item_name(id);        PBItems.getName(id); end
    def self.item_description(id); pbGetMessage(MessageTypes::ItemDescriptions, id); end
    def self.species_name(id);     PBSpecies.getName(id); end
    def self.ability_name(id);     PBAbilities.getName(id); end
    def self.nature_name(id);      PBNatures.getName(id); end
    def self.status_name(st);      PokeAccess::Config.status_names[st]; end
    def self.stat_name(s);         PBStats.getName(s); end

    # The species pokedex entry as [name, category, dex_text] from the gen-6 message tables.
    def self.species_entry(id)
      [PBSpecies.getName(id), (pbGetMessage(MessageTypes::Kinds, id) rescue nil),
       (pbGetMessage(MessageTypes::Entries, id) rescue nil)]
    end

    # The spoken type names of a pokemon, from its gen-6 numeric type1/type2.
    def self.pokemon_types(pk)
      [PBTypes.getName(pk.type1), (pk.type2 != pk.type1 ? PBTypes.getName(pk.type2) : nil)].compact
    end

    # Resolves an item symbol parsed from an event script to [id, name]. The gen-6 tables are keyed by
    # numeric id, so the symbol is mapped through the PBItems constant (or getID).
    def self.item_id(sym)
      id = (PBItems.const_get(sym) rescue nil)
      id = (getID(PBItems, sym.to_sym) rescue nil) if id.nil?
      [id, (id ? (PBItems.getName(id) rescue nil) : nil)]
    end
  end
end

PokeAccess::Data.register(10, PokeAccess::DataG6) if defined?(PBMoves) && !defined?(GameData)
