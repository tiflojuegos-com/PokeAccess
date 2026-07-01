module PokeAccess
  # Data resolution layer: turns an id/symbol into a spoken name or basic field without the caller knowing
  # which engine answers. Each engine registers a provider (gen-6 PB* tables, modern GameData, any future
  # Essentials its own); the highest-priority provider present serves, and a last-resort fallback
  # (core/data/data_fallback.rb, priority 0) is always present so there is never NO provider. Shared readers
  # call PokeAccess::Data.* and never branch on the engine, so a new data API is one new provider file --
  # no caller changes, and nothing is assumed constant across versions.
  module Data
    @providers = []

    # Registers an engine's data provider. param priority higher wins when several are registered, so a
    # newer engine overrides an older fallback
    def self.register(priority, provider)
      @providers.push([priority, provider]); @active_entry = nil
    end

    # The [priority, provider] of the active provider (highest priority registered), or nil if none.
    def self.active_entry
      @active_entry ||= @providers.max_by { |pr| pr[0] }
    end

    # The active provider, or nil if none registered.
    def self.active
      e = active_entry; e && e[1]
    end

    # The priority of the active provider, or nil. 0 means only the emergency fallback registered (no real
    # engine provider) -- boot surfaces that so an unrecognised engine is never a silent dead state.
    def self.active_priority
      e = active_entry; e && e[0]
    end

    # Resolves one datum through the active provider. nil when no provider is present or the datum is
    # genuinely absent (the intended silence). A provider EXCEPTION (a likely bug, not just absence) is
    # recorded once and surfaced as a diagnostic, then returns nil so the reader degrades, never crashes.
    def self.resolve(method, arg)
      pr = active
      return nil unless pr
      begin
        pr.send(method, arg)
      rescue StandardError => e
        note_error(method, e)
        nil
      end
    end

    # Records a provider exception once per (method, class) and writes it to the load marker, so a provider
    # bug shows up as a diagnostic instead of a permanently silent reader.
    def self.note_error(method, e)
      @errors ||= {}
      key = "#{method}:#{e.class}"
      return if @errors[key]
      @errors[key] = "#{method}: #{e.class}: #{e.message}"
      (PokeAccess.write_marker("data provider error -- #{@errors[key]}\n") rescue nil)
    end

    # The recorded provider errors (empty on a clean run); for diagnostics.
    def self.errors; (@errors || {}).values; end

    #resolvers -- each forwards through resolve (nil-safe; a provider exception is recorded, not crashed).
    def self.move_name(id);        resolve(:move_name, id); end
    def self.move_power(id);       resolve(:move_power, id); end
    def self.move_accuracy(id);    resolve(:move_accuracy, id); end
    def self.move_type_name(id);   resolve(:move_type_name, id); end
    def self.move_description(id); resolve(:move_description, id); end
    def self.type_name(id);        resolve(:type_name, id); end
    def self.item_name(id);        resolve(:item_name, id); end
    def self.item_description(id); resolve(:item_description, id); end
    def self.species_name(id);     resolve(:species_name, id); end
    def self.species_entry(id);    resolve(:species_entry, id); end
    def self.ability_name(id);     resolve(:ability_name, id); end
    def self.nature_name(id);      resolve(:nature_name, id); end
    def self.stat_name(s);         resolve(:stat_name, s); end
    def self.status_name(st);      resolve(:status_name, st); end
    def self.pokemon_types(pk);    resolve(:pokemon_types, pk) || []; end
    def self.item_id(sym);         resolve(:item_id, sym); end
  end
end
