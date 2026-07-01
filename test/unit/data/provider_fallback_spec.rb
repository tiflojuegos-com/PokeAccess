require "tempfile"

# Emergency-fallback provider: when NO real engine provider is registered, DataFallback (priority 0) is the
# active one and speaks the raw id rather than going silent -- the safety net for an unrecognised engine.
# The full harness always registers a real provider (gen-6 or modern, priority >= 10) that outranks the
# fallback, so this can never be the active provider in-process. It is therefore exercised in an isolated
# child Ruby that loads ONLY the data layer + the fallback, and we assert on that child's verdict.
Suite.define("data: emergency fallback speaks the raw id") do
  root = File.expand_path("../../..", File.dirname(__FILE__))
  script = <<-RUBY
    module PokeAccess; def self.write_marker(*); end; end
    load File.expand_path("core/data/data.rb", #{root.inspect})
    load File.expand_path("core/data/data_fallback.rb", #{root.inspect})
    d = PokeAccess::Data
    bad = []
    chk = lambda { |n, c| bad << n unless c }
    chk.call("fallback is the active provider", d.active == PokeAccess::DataFallback)
    chk.call("active_priority is 0 (emergency)", d.active_priority == 0)
    chk.call("move_name raw id", d.move_name(:TACKLE) == "TACKLE")
    chk.call("item_name raw id", d.item_name(:POTION) == "POTION")
    chk.call("species_name raw id", d.species_name(7) == "7")
    chk.call("move_power nil", d.move_power(:TACKLE).nil?)
    chk.call("pokemon_types empty", d.pokemon_types(nil) == [])
    chk.call("species_entry id only", d.species_entry(:X) == ["X", nil, nil])
    print(bad.empty? ? "OK" : "FAIL: " + bad.join(", "))
  RUBY
  file = Tempfile.new(["pa_fallback", ".rb"])
  begin
    file.write(script); file.close
    out = `ruby "#{file.path}" 2>&1`
  ensure
    file.unlink
  end
  eq "isolated fallback load reports OK", out.strip, "OK"
end
