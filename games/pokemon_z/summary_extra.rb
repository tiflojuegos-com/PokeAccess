module PokeAccess
  # Pokemon Z specific summary extra: the EV/IV sub-screen (Z's custom "Habilidades", reached with Accept
  # on the stats page) which is not part of the shared gen-6 summary. The move-reorder feedback is generic
  # and lives in core (PokeAccess::Summary).
  module ZSummary
    # The EV/IV sub-screen: ability, effort and individual values, happiness, hidden power.
    def self.ev_iv_text(pk)
      return nil unless pk
      ev = (pk.ev rescue nil); iv = (pk.iv rescue nil)
      return nil unless ev.is_a?(Array) && iv.is_a?(Array)
      t = "Informacion. Habilidad #{PBAbilities.getName(pk.ability) rescue ''}. "
      t += "Esfuerzos: PS #{ev[0]}, Ataque #{ev[1]}, Defensa #{ev[2]}, Velocidad #{ev[3]}, Ataque especial #{ev[4]}, Defensa especial #{ev[5]}. "
      t += "Geneticos: PS #{iv[0]}, Ataque #{iv[1]}, Defensa #{iv[2]}, Velocidad #{iv[3]}, Ataque especial #{iv[4]}, Defensa especial #{iv[5]}. "
      t += "Felicidad #{pk.happiness}." if pk.respond_to?(:happiness)
      hp = (pbHiddenPower(iv) rescue nil)
      t += " Poder oculto #{PBTypes.getName(hp[0]) rescue ''}." if hp
      t
    rescue StandardError
      nil
    end
  end
end

# EV/IV sub-screen (Z's Habilidades, reached with Accept on the stats page): read on entry.
PokeAccess::Game.define("pokemon_z") do
  before("PokemonSummaryScene", :Habilidades) do |_s, args|
    PokeAccess.speak(PokeAccess::ZSummary.ev_iv_text(args[0]), false)
  end
end
