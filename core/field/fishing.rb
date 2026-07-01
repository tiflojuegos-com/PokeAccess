module PokeAccess
  # Fishing has a reflex test: when a Pokemon bites, the engine shows "Oh! A bite!" and waits a fraction
  # of a second for the button -- invisible to a screen-reader player -- so the bite is announced the
  # instant the reflex test starts, in time to react.
  def self.say_fishing_bite
    speak(I18n.t(:fish_bite), true)
  end
end

# pbWaitForInput is the fishing reflex test (and nothing else) in both engines, a top-level method;
# announce the bite before it blocks for the button.
PokeAccess::Hooks.wrap_global("pbWaitForInput", "hook_fishing", :before) { |_args, _r| PokeAccess.say_fishing_bite }
