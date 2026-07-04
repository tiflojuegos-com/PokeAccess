module PokeAccess
  # Realidea's sticker album (Albumfotos): a 2x3 grid of collectible cards with no command window. inputs
  # runs every frame; @selec (0..5) is the cursor over the current @pagina of @paginas, and the focused
  # card id is (@selec+1)+(@pagina-1)*6 (filled when its fotito sprite is visible). Pressing C opens the
  # card detail (@sprites["foto"] visible), and flipping it (@girado) reveals the illustrator from @info1.
  # Read the focus when grid position, page, detail or flip state changes.
  module RealideaAlbum
    # The album state to dedup on: detail-vs-grid, cursor, page and flip.
    def self.state(scene)
      detail = (scene.instance_variable_get(:@sprites)["foto"].visible rescue false)
      [detail,
       PokeAccess.ivar(scene, :@selec),
       PokeAccess.ivar(scene, :@pagina),
       (scene.instance_variable_get(:@girado) rescue false)]
    rescue StandardError
      nil
    end

    # The spoken line for the current focus.
    def self.line(scene)
      sel = (scene.instance_variable_get(:@selec) rescue 0)
      page = (scene.instance_variable_get(:@pagina) rescue 1)
      pages = (scene.instance_variable_get(:@paginas) rescue 1)
      sprites = PokeAccess.ivar(scene, :@sprites)
      detail = (sprites && sprites["foto"].visible rescue false)
      card = (sel + 1) + (page - 1) * 6
      if detail
        if (scene.instance_variable_get(:@girado) rescue false)
          info = PokeAccess.ivar(scene, :@info1)
          author = (info && info[card - 1]) ? info[card - 1].to_s : ""
          return PokeAccess.clean(author)
        end
        return PokeAccess::I18n.t(:album_card, :n => card)
      end
      filled = (sprites && sprites["fotito#{sel + 1}"] && sprites["fotito#{sel + 1}"].visible rescue false)
      st = filled ? PokeAccess::I18n.t(:album_have) : PokeAccess::I18n.t(:album_empty)
      PokeAccess::I18n.t(:album_slot, :n => card, :page => page, :pages => pages, :state => st)
    rescue StandardError
      nil
    end

    # Reads the focus when it changes.
    def self.announce(scene)
      st = state(scene)
      return unless PokeAccess::Cursor.changed?(scene, :album_state, st)
      t = line(scene)
      PokeAccess.speak(t, true) if t && !t.to_s.empty?
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("realidea") do
  after("Albumfotos", :inputs) { |scene, _result, _args| PokeAccess::RealideaAlbum.announce(scene) }
end
