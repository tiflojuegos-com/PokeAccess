# Armonia photo gallery (AlbumScene, the "Galeria" pause-menu entry). Each page holds 4 photos that are
# images with no text, unlocked per $game_switches[ALBUM_SWITCHES[i]]. showPage runs on open and on every
# left/right, so announce the page and how many of its 4 photos are unlocked.
PokeAccess::Game.define("armonia") do
  after("AlbumScene", :showPage) do |_scene, _result, args|
    page = args[0].to_i
    unlocked = 0
    4.times { |f| i = page * 4 + f; unlocked += 1 if ($game_switches[ALBUM_SWITCHES[i]] rescue false) }
    total = (ALBUM_PAGES rescue nil)
    of_total = total ? " de #{total}" : ""
    PokeAccess.speak("Galeria, pagina #{page + 1}#{of_total}, #{unlocked} de 4 fotos desbloqueadas", true)
  end
end
