# Reminiscencia v2.3 profile: same Essentials base as the core defaults. Its currency is shown as a bare
# "$" (not "pokedolares"), so the spoken money uses a neutral label.
PokeAccess::Game.define("reminiscencia") do
  config(:money_label, :tr_money_generic)
end
