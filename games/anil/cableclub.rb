module PokeAccess
  # Online play setup (Cable Club plugin). CableClub_Scene#pbShowCommands draws its question
  # straight onto a message-box sprite (not via pbMessage), so the prompt is mute; the option
  # list itself is a Window_CommandPokemon read by the core menu hook. Read the question here so
  # the whole online-battle/trade setup flow is accessible. The actual online battle uses
  # Battle::Scene and is already covered by the combat reader.
end

PokeAccess::Game.define("anil") do
  before("CableClub_Scene", :pbShowCommands) do |_s, args|
    PokeAccess.speak(PokeAccess.clean(args[0]), false)
  end
end
