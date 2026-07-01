# Regression: hooks must bind to private methods too. initialize is always private in Ruby, so a reader
# that hooks a custom scene's initialize (e.g. Awakening's EncounterListUI) was silently never wrapped while
# wrap only checked method_defined? (public methods). wrap now also accepts private_method_defined? and
# keeps the method private afterwards.
Suite.define("hooks: before/after bind to a private method (initialize)") do
  klass = Class.new do
    def initialize; @made = true; end
    def made?; @made; end
  end
  Object.const_set(:PaHookInitProbe, klass) unless Object.const_defined?(:PaHookInitProbe)
  fired = []
  PokeAccess::Hooks.after_hook("PaHookInitProbe", :initialize) { |_i, _r, _a| fired << :after }
  obj = PaHookInitProbe.new
  truthy "the original initialize still ran (object constructed)", obj.made?
  eq "the after-hook fired on a private initialize", [:after], fired
  truthy "initialize stayed private", PaHookInitProbe.private_method_defined?(:initialize)
end
