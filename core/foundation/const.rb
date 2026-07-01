module PokeAccess
  # Resolves a "A::B::C" constant by name, returning the constant or nil. Walks segment by segment so it is
  # safe on Ruby 1.8.7, whose const_defined? rejects a name containing "::" (gen-6 runs 1.8.7). This is the
  # one low-level constant lookup the whole mod builds on -- Hooks, Input and Engine.has? all route through
  # it instead of calling Object.const_defined? on a "::" string directly, so a nested class name never
  # crashes the gen-6 loader. Lives in foundation so it loads before anything that needs it.
  # @param name a constant name string (may be nested with "::")
  # @return the constant, or nil if any segment is undefined
  def self.const_at(name)
    name.to_s.split("::").inject(Object) do |mod, seg|
      return nil unless mod.const_defined?(seg)
      mod.const_get(seg)
    end
  rescue StandardError
    nil
  end

  # True if the named constant is currently defined (1.8.7-safe, see const_at).
  # @param name a constant name string (may be nested with "::")
  def self.const?(name)
    !const_at(name).nil?
  end
end
