# Reminiscencia's pbShowCommandsWithHelp draws its help into Window_AdvancedTextPokemonCentro, a class of
# its own that does NOT descend from Window_AdvancedTextPokemon, so the core listener never sees it. Add the
# listener on this game's class, declaring it serves the :withhelp variant; it routes through the shared
# PokeAccess::CommandHelp so it only fires inside that menu (never on dialogue) and honours read_help.
PokeAccess::Game.define("reminiscencia") do
  after("Window_AdvancedTextPokemonCentro", :text=) do |win, _result, args|
    PokeAccess::CommandHelp.note(win, :withhelp, args[0])
  end
end
