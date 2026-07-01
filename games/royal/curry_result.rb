# royal's curry result screens ([ROYAL] Curry): ResultadosCurry_Scene shows the dish made and
# ResultadosCurryPuntos_Scene the quality rank. Both are non-navigable displays whose key text is drawn as
# an overlay (not a message), so announce it on open: the curry name (@tipo_de_curry[1]) and the rank
# (@pokemon_puntos, a Pokemon name standing for quality -- Charizard best, Koffing worst). The
# congratulation/happiness lines use pbMessageBlack and are already voiced by the dialogue hook.
PokeAccess::Game.define("royal") do
  after("ResultadosCurry_Scene", :pbStartScene) do |scr, _ret, _args|
    curry = (scr.instance_variable_get(:@tipo_de_curry) rescue nil)
    if curry.is_a?(Array) && curry[1] && !curry[1].to_s.empty?
      PokeAccess.speak(PokeAccess.clean("Has cocinado #{curry[1]}"), true)
    end
  end

  after("ResultadosCurryPuntos_Scene", :pbStartScene) do |scr, _ret, _args|
    rank = (scr.instance_variable_get(:@pokemon_puntos) rescue nil)
    if rank && !rank.to_s.empty?
      PokeAccess.speak(PokeAccess.clean("Digno de un #{rank}"), true)
    end
  end
end
