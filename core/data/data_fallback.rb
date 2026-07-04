module PokeAccess
  # Emergency data provider, registered unconditionally at the lowest priority so PokeAccess::Data always
  # has an active provider -- even on an engine the real providers (gen-6 PB*, modern GameData) do not
  # recognise. It speaks the raw id (far better than silence for a screen-reader user) and leaves rich
  # fields nil; any real engine provider (priority >= 10) outranks it. Boot logs when this is the active
  # provider, so an unrecognised engine surfaces loudly instead of muting.
  module DataFallback
    def self.move_name(id);        id.to_s; end
    def self.move_power(id);       nil; end
    def self.move_accuracy(id);    nil; end
    def self.move_type_name(id);   nil; end
    def self.move_description(id); nil; end
    def self.type_name(id);        id.to_s; end
    def self.item_name(id);        id.to_s; end
    def self.item_name_plural(id);  id.to_s; end
    def self.item_description(id); nil; end
    def self.species_name(id);     id.to_s; end
    def self.species_entry(id);    [id.to_s, nil, nil]; end
    def self.ability_name(id);     id.to_s; end
    def self.nature_name(id);      id.to_s; end
    def self.stat_name(s);         s.to_s; end
    def self.status_name(st);      nil; end
    def self.pokemon_types(pk);    []; end
    def self.item_id(sym);         [sym, sym.to_s]; end
  end
end

PokeAccess::Data.register(0, PokeAccess::DataFallback)
