module PokeAccess
  # royal's photo album ([ROYAL] Fotos del equipo -> AlbumFotos_Scene): a 2x2 grid of saved screenshots over
  # pages, cursor in @photo (0-3) and @page; @viendofoto is set while one is enlarged. The photos are game
  # screenshots (no text content), so the accessible part is the focused slot's number and date (parsed from
  # the capture###_dd_mm_yyyy.png filename), or "vacío" for an empty slot. pbUpdateAlbum runs the navigation
  # loop (calling Input.update), so the cursor is polled each frame while the scene is held.
  module RoyalAlbum
    @scene = nil; @last = nil
    def self.watch(s); @scene = s; @last = nil; end
    def self.unwatch; @scene = nil; @last = nil; end

    def self.poll
      s = @scene
      return unless s
      page    = PokeAccess.ivar_i(s, :@page)
      photo   = PokeAccess.ivar_i(s, :@photo)
      viewing = (s.instance_variable_get(:@viendofoto) rescue false)
      key = [page, photo, viewing]
      return if key == @last
      @last = key
      idx   = page * 4 + photo
      total = PokeAccess.ivar_i(s, :@numcapturas)
      pages = (s.instance_variable_get(:@numpages) rescue 1).to_i
      file  = (s.send(:obtener_archivo_captura, idx) rescue nil)
      if file
        parts = File.basename(file.to_s, ".png").split("_")
        date  = (parts.length >= 3) ? "#{parts[-3]}/#{parts[-2]}/#{parts[-1]}" : nil
        txt = "Foto #{idx + 1} de #{total}"
        txt += ", #{date}" if date
        txt += ", página #{page + 1} de #{pages}"
        PokeAccess.speak(txt, true)
      else
        PokeAccess.speak("Hueco vacío, página #{page + 1} de #{pages}", true)
      end
    rescue StandardError
      nil
    end
  end
end

PokeAccess::SceneWatcher.wire("AlbumFotos_Scene", :pbUpdateAlbum, PokeAccess::RoyalAlbum)
