# Hook chaining: several hooks on the same method must all run (an onion), the original's return value is
# preserved, and hooking a parent then a child that overrides the same method (with super) keeps the child's
# logic and its super chain intact -- the real game Options-screen case. Targets are defined here; after_hook
# patches the method when called, so load order does not matter.
Suite.define("hooks: multiple after-hooks chain and keep the result") do
  klass = Class.new { def greet(x); x * 2; end }
  Object.const_set(:HookChainTarget, klass) unless Object.const_defined?(:HookChainTarget)
  log = []
  PokeAccess::Hooks.after_hook("HookChainTarget", :greet) { |_i, r, _a| log << "A:#{r}" }
  PokeAccess::Hooks.after_hook("HookChainTarget", :greet) { |_i, r, _a| log << "B:#{r}" }
  result = HookChainTarget.new.greet(5)
  eq "hook preserves the original result", result, 10
  truthy "both after-hooks on the same method run", log.include?("A:10") && log.include?("B:10")
end

# Parent + overriding child: a hook on the base and a hook on the child must both fire, and the child's own
# body plus its super call must still run, in order: child body, base (via super), then the base hook, then
# the child hook.
Suite.define("hooks: parent and overriding child both fire, super intact") do
  log = []
  base = Class.new { define_method(:step) { log << "base" } }
  Object.const_set(:HookSuperBase, base) unless Object.const_defined?(:HookSuperBase)
  child = Class.new(HookSuperBase) { define_method(:step) { log << "child"; super() } }
  Object.const_set(:HookSuperChild, child) unless Object.const_defined?(:HookSuperChild)
  PokeAccess::Hooks.after_hook("HookSuperBase", :step) { |_i, _r, _a| log << "HB" }
  PokeAccess::Hooks.after_hook("HookSuperChild", :step) { |_i, _r, _a| log << "HC" }
  log.clear
  HookSuperChild.new.step
  eq "child body, super, then both hooks in order", log, ["child", "base", "HB", "HC"]
end

# The typo detector (Hooks.missing): a binding whose CLASS exists but METHOD does not is recorded (a likely
# typo -> a permanently dead feature); a binding whose whole class is absent is NOT recorded (normal
# cross-game variance, handled silently). Unique names so other suites cannot pollute the assertion.
Suite.define("hooks: missing records typo, ignores absent class") do
  target = Class.new { def real_method; end }
  Object.const_set(:HookMissTarget, target) unless Object.const_defined?(:HookMissTarget)
  PokeAccess::Hooks.after_hook("HookMissTarget", :typo_method) { |_i, _r, _a| }
  PokeAccess::Hooks.after_hook("HookNoSuchClassXYZ_pa", :whatever) { |_i, _r, _a| }
  truthy "method absent on a real class is recorded",
         PokeAccess::Hooks.missing.include?("HookMissTarget#typo_method")
  falsy "absent class is not recorded",
        PokeAccess::Hooks.missing.include?("HookNoSuchClassXYZ_pa#whatever")
end

# wrap_global: the shared helper that replaced six copy-pasted Object-method wraps. :after runs after the
# original and sees its return value; :before runs first with a nil result; the original's return is
# preserved; it never double-wraps. Throwaway Object methods stand in for the real (stubbed-away) sites.
Suite.define("hooks: wrap_global timing, return value and no double-wrap") do
  wg = []
  Object.send(:define_method, :pa_wg_after) { |x| wg.push([:orig, x]); x * 2 }
  PokeAccess::Hooks.wrap_global("pa_wg_after", "hook_t1", :after) { |args, r| wg.push([:after, args[0], r]) }
  PokeAccess::Hooks.wrap_global("pa_wg_after", "hook_t1", :after) { |args, r| wg.push([:dup, r]) }
  res = pa_wg_after(5)
  eq "after preserves the return value", res, 10
  eq "after runs once, after the original", wg, [[:orig, 5], [:after, 5, 10]]

  wg2 = []
  Object.send(:define_method, :pa_wg_before) { |x| wg2.push([:orig, x]); x }
  PokeAccess::Hooks.wrap_global("pa_wg_before", "hook_t2", :before) { |args, r| wg2.push([:before, args[0], r]) }
  pa_wg_before(7)
  eq "before runs first with a nil result", wg2, [[:before, 7, nil], [:orig, 7]]
  PokeAccess::Hooks.wrap_global("pa_wg_missing_xyz", "hook_t3") { |_a, _r| }
  eq "wrapping a missing method does not define it", Object.method_defined?(:pa_wg_missing_xyz), false
  eq "wrapping a missing method creates no alias", Object.method_defined?(:pa_wg_missing_xyz__pa), false
end

# Failure path: a throwing hook/poller body must be logged-once and SWALLOWED, never propagated -- a reader
# bug must not crash a wrapped global or the per-frame input loop. Guards the regression where the call sites
# referenced an undefined log_once (the suite was green because nothing exercised the rescue branch).
Suite.define("hooks: a throwing body is swallowed, not propagated") do
  truthy "log_once is defined", PokeAccess.respond_to?(:log_once)
  Object.send(:define_method, :pa_wg_raise) { |x| x + 1 }
  PokeAccess::Hooks.wrap_global("pa_wg_raise", "hook_t4", :after) { |_a, _r| raise "boom" }
  safe = (begin; pa_wg_raise(4); rescue StandardError; :propagated; end)
  eq "throwing after-body does not propagate, return preserved", safe, 5

  PokeAccess::Keys.on_frame { raise "poller boom" }
  poller = (begin; PokeAccess::Keys.run_frame_pollers; :ok; rescue StandardError; :propagated; end)
  eq "a throwing per-frame poller does not propagate", poller, :ok
end
