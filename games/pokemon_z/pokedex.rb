# Pokedex entry (AdvancedPokedexScene, script 205, custom). Its own module (not core's PokeAccess::Pokedex)
# so this game-specific reader never collides with the shared dex helper.
module PokeAccess
  module ZPokedex
    # Builds the text of the current dex page (info / level moves / egg moves).
    def self.page_text(scene)
      page  = scene.instance_variable_get(:@page)
      total = scene.instance_variable_get(:@totalPages)
      return nil unless page && total && total > 0
      infoP = scene.instance_variable_get(:@infoPages) || 0
      lvlP  = scene.instance_variable_get(:@levelMovesPages) || 0
      out = ["Pagina #{page} de #{total}."]
      if page <= infoP
        info = scene.instance_variable_get(:@infoArray) || []
        (12 * (page - 1)...12 * page).each do |i|
          col = i / 6
          v = (info[col] ? info[col][i % 6] : nil)
          out.push(v.to_s) if v && !v.to_s.strip.empty?
        end
      elsif page <= infoP + lvlP
        out.push("Movimientos por nivel:")
        arr = scene.instance_variable_get(:@levelMovesArray) || []
        p2 = page - infoP
        (10 * (p2 - 1)...10 * p2).each { |i| out.push(arr[i].to_s) if arr[i] }
      else
        out.push("Movimientos huevo:")
        arr = scene.instance_variable_get(:@eggMovesArray) || []
        p2 = page - infoP - lvlP
        (10 * (p2 - 1)...10 * p2).each { |i| out.push(arr[i].to_s) if arr[i] }
      end
      out.join(" ")
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("pokemon_z") do
  # Entry open: name + types + first page (or a not-owned notice).
  after("AdvancedPokedexScene", :pbStartScene) do |scene, _r, _a|
    sp = scene.instance_variable_get(:@species)
    name = (PBSpecies.getName(sp) rescue "Pokemon")
    t1 = scene.instance_variable_get(:@type1)
    t2 = scene.instance_variable_get(:@type2)
    ty = PokeAccess::Util.types_phrase((PBTypes.getName(t1) rescue nil), (PBTypes.getName(t2) rescue nil))
    head = "#{name}."
    head += " Tipo #{ty}." unless ty.empty?
    body = PokeAccess::ZPokedex.page_text(scene)
    PokeAccess.speak(body ? "#{head} #{body}" : "#{head} Sin datos, no capturado.", true)
    scene.instance_variable_set(:@access_started, true)
  end

  # Page change (C/A): read the new page; the flag avoids doubling the startScene read.
  after("AdvancedPokedexScene", :displayPage) do |scene, _r, _a|
    if scene.instance_variable_get(:@access_started)
      t = PokeAccess::ZPokedex.page_text(scene)
      PokeAccess.speak(t, true) if t
    end
  end
end
