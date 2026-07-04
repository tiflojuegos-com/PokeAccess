# The single test runner: loads the toolkit under the chosen engine stubs, requires every spec (which
# register suites), runs each suite under a fresh reset, and tallies pass/fail with traceable output.
# Then, only in the default (gen6) pass, runs the static checks (manifest, i18n parity warning, ruby187)
# and re-invokes itself for the gamedata engine. Usage:
#   ruby test/run_all.rb                  # both engines + static checks
#   ruby test/run_all.rb behavior/battle  # only specs whose path matches the filter (current engine)
# Exit code is non-zero if any assertion failed. That includes i18n parity: the static spec asserts
# it, so a drifted lang/ key fails CI on purpose (the runner's own parity print is just a warning).
SUPPORT = File.expand_path("support", File.dirname(__FILE__))
require File.join(SUPPORT, "harness")
require File.join(SUPPORT, "framework")
require File.join(SUPPORT, "speak_capture")
require File.join(SUPPORT, "reset")
require File.join(SUPPORT, "poke_builder")
require File.join(SUPPORT, "world_builder")

PROFILE = (ENGINE == :gamedata ? "anil" : "pokemon_z")
FILTER = ARGV.find { |a| a !~ /^--/ }

# Loads the toolkit; a load error is reported as a failed implicit suite and aborts (nothing else can run).
load_errors = Harness.load_all(PROFILE)
unless load_errors.empty?
  puts "[#{ENGINE}] LOAD FAILED:"
  load_errors.first(10).each { |e| puts "  #{e}" }
  exit 1
end
SpeakCapture.install

# Requires the spec files for this engine. gen6 runs unit + the gen6/agnostic behaviour; gamedata runs the
# behaviour specs tagged _gd (the modern path). A path filter narrows the glob for focused local runs.
testdir = File.expand_path(File.dirname(__FILE__))
specs = Dir.glob(File.join(testdir, "{unit,behavior,static}", "**", "*_spec.rb")).sort
specs = specs.select { |p| ENGINE == :gamedata ? p =~ /_gd_spec\.rb$/ : p !~ /_gd_spec\.rb$/ }
specs = specs.select { |p| p.include?(FILTER) } if FILTER

Assert.pass = 0; Assert.fail = 0; Assert.failures = []

# Loading a spec runs its top-level code (requires, target class/method setup). A failure there -- a renamed
# game file required by a spec, a typo in a spec's top-level -- must be attributed to that file and not abort
# the whole run: without this the exception propagates, sibling specs never load, the gamedata pass is skipped
# and no summary prints. Mirrors how harness reports a toolkit load error as its own failure, not a crash.
specs.each do |f|
  begin
    require f
  rescue StandardError, LoadError => e
    Assert.suite = File.basename(f)
    Assert.check("spec failed to load", false, "#{e.class}: #{e.message}")
    puts "  FAIL(load)  #{File.basename(f)}"
  end
end

Suite.all.each do |name, body|
  Reset.between_suites
  Assert.suite = name
  before = Assert.fail
  begin
    body.call
  rescue StandardError => e
    Assert.check("suite raised", false, "#{e.class}: #{e.message}")
  end
  added_fail = Assert.fail - before
  status = added_fail > 0 ? "FAIL(#{added_fail})" : "ok"
  puts "  #{status}  #{name}"
end

puts "\n[#{ENGINE}] #{Assert.pass} ok, #{Assert.fail} fail"
Assert.failures.each { |f| puts "  #{f}" }
engine_fail = Assert.fail

# The static checks and the second engine pass run only in the primary (gen6) invocation.
extra_fail = 0
if ENGINE == :gen6
  puts "\n=== static checks ==="
  ok187 = system("python", File.join(File.dirname(__FILE__), "check187.py"))
  puts "ruby187: #{ok187 ? 'OK' : 'FAIL'}"; extra_fail += 1 unless ok187
  okman = system("ruby", File.join(File.dirname(__FILE__), "static", "manifest_check.rb"))
  extra_fail += 1 unless okman
  par = (PokeAccess::I18n.parity_issues rescue [])
  puts(par.empty? ? "i18n parity: OK" : "i18n parity WARNING (no rompe CI): #{par.first(10).join(', ')}")

  puts "\n=== gamedata engine ==="
  ok_gd = system({ "PA_ENGINE" => "gamedata" }, "ruby", __FILE__)
  extra_fail += 1 unless ok_gd
end

exit((engine_fail + extra_fail) == 0 ? 0 : 1)
