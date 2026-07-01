module PokeAccess
  module Util
    # Joins parts into one spoken line, dropping nils and blanks. The recurring "name. detail. extra" idiom
    # where any piece may be absent (so no stray ". ." or leading separator). 1.8.7-safe.
    def self.join_parts(parts, sep = ". ")
      parts.reject { |s| s.nil? || s.to_s.strip.empty? }.join(sep)
    end

    # A "type1/type2" phrase from two already-resolved type names, collapsing a single-type Pokemon to one
    # name and dropping blanks. For callers that hold loose type names (e.g. a scene's @type1/@type2), not a
    # Pokemon object -- those should use PokeAccess::Data.pokemon_types(pk) instead.
    def self.types_phrase(t1, t2)
      types = [t1, t2].reject { |t| t.nil? || t.to_s.empty? }
      types.uniq.join("/")
    end
  end
end
