# royal's League Cards list ([ROYAL] Tarjetas Liga -> class TarjetasLiga_Scene): a sprite grid, @index is
# the on-screen slot and @tarjeta_elegida the actual card index into TarjetasLiga.tarjetas (each card is an
# array: [id, name, ?, description]). actualizarTarjetasPantalla redraws on every cursor move, so read the
# focused card's name and description there, deduped by the chosen card index.
PokeAccess::Game.define("royal") do
  after("TarjetasLiga_Scene", :actualizarTarjetasPantalla) do |scn, _ret, _args|
    i = (scn.instance_variable_get(:@tarjeta_elegida) rescue nil)
    if i && i != (scn.instance_variable_get(:@access_tl) rescue nil)
      scn.instance_variable_set(:@access_tl, i)
      card = (TarjetasLiga.tarjetas[i] rescue nil)
      if card.is_a?(Array)
        parts = [card[1], card[3]].compact.reject { |s| s.to_s.empty? }
        PokeAccess.speak(PokeAccess.clean(parts.join(". ")), true) unless parts.empty?
      end
    end
  end
end
