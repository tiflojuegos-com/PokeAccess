# v22 trainer card (Essentials v22: UI::TrainerCard): the same static $player panel (name, ID, money,
# pokedex tally, badges, play time) with nothing to navigate, read all once on open. The spoken content is
# the agnostic TrainerCardData (no dependency on the v21 file).
if PokeAccess::V22.const_exists?("UI::TrainerCard")
  PokeAccess::Hooks.after_hook("UI::TrainerCard", :start_screen) do |_screen, _ret, _args|
    PokeAccess.speak(PokeAccess::TrainerCardData.text, false)
  end
end
