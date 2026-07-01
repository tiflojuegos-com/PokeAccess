module PokeAccess
  # Command windows: per-class extractor dispatch over Window_DrawableCommand.
  module Menus
    EXTRACTORS = []

    # Registers an extractor for a window class. yields (window, index) -> the focused option text
    def self.def_extractor(cname, &blk)
      EXTRACTORS.push([cname, blk])
    end

    # Reads the focused entry of a sprite-driven menu (no command window to introspect) on cursor change,
    # deduped per scene instance via Cursor. The entries live in items_ivar, the cursor in @index; the block
    # maps the focused entry to its spoken name. Shared by the ready menu, the pokegear theme picker and Neo
    # PauseMenu. param items_ivar the ivar symbol holding the entry array; param dedup_ivar the slot symbol
    # for the dedup state (kept for call-site compatibility)
    def self.poll_sprite_menu(scene, items_ivar, dedup_ivar)
      items = (scene.instance_variable_get(items_ivar) rescue nil)
      idx = (scene.instance_variable_get(:@index) rescue nil)
      return unless items.is_a?(Array) && idx && idx >= 0 && idx < items.length
      PokeAccess::Cursor.announce(scene, dedup_ivar, idx) { yield(items[idx]) }
    rescue StandardError => e
      PokeAccess.log_once("poll_sprite_#{scene.class}", e)
    end

    # The focused option's text for a command window, via the matching extractor or generic_focus.
    def self.focused_text(win)
      i = win.index
      return nil if i.nil? || i < 0
      EXTRACTORS.each do |cname, blk|
        k = PokeAccess.const_at(cname)
        if k && win.is_a?(k)
          begin
            return blk.call(win, i)
          rescue StandardError => e
            log = (@ext_logged ||= [])
            unless log.include?(cname)
              log << cname
              PokeAccess.write_marker("extractor #{cname}: #{e.class}: #{e.message}\n")
            end
            return nil
          end
        end
      end
      generic_focus(win, i)
    end

    # The ivars an Essentials selectable window commonly stores its option list in, tried in order
    # (introspection, never OCR), so list[index] yields the exact string the game holds.
    LIST_IVARS = [:@commands, :@items, :@list, :@data, :@choices, :@names, :@entries, :@stock]

    # The focused entry's text by introspecting the window's own option list, or nil; the fallback for
    # command windows and the reader for the generic Window_Selectable hook.
    def self.generic_focus(win, i)
      LIST_IVARS.each do |iv|
        lst = (win.instance_variable_get(iv) rescue nil)
        next unless lst.is_a?(Array) && i >= 0 && i < lst.length
        t = entry_text(lst[i])
        return t if t && !t.empty?
      end
      nil
    end

    # Resolves one list entry to spoken text conservatively: a String/Symbol directly, else its .name or
    # .text when a non-empty String; anything else returns nil, so the reader stays silent over garbage.
    def self.entry_text(e)
      return nil if e.nil?
      return e if e.is_a?(String)
      return e.to_s if e.is_a?(Symbol)
      nm = (e.name rescue nil); return nm if nm.is_a?(String) && !nm.empty?
      tx = (e.text rescue nil); return tx if tx.is_a?(String) && !tx.empty?
      nil
    end

    #base extractors (shared across Essentials fangames)

    def_extractor("Window_PokemonOption") do |win, i|
      opts = win.instance_variable_get(:@options)
      next PokeAccess::I18n.t(:sm_exit) if i >= opts.length
      o = opts[i]
      "#{o.name}: #{PokeAccess::Options.value_of(o, win[i])}"
    end

    # Bag: the pocket name is prefixed only when the pocket changes, so switching category and the
    # focused item are read in a single utterance.
    def_extractor("Window_PokemonBag") do |win, i|
      bag = win.instance_variable_get(:@bag)
      pocket = win.pocket
      prefix = ""
      if pocket != (win.instance_variable_get(:@access_bag_pocket) rescue nil)
        win.instance_variable_set(:@access_bag_pocket, pocket)
        pn = (PokemonBag.pocketNames[pocket] rescue nil)
        pn = (PokemonBag.pocket_names[pocket - 1] rescue nil) if pn.nil? || pn.to_s.empty?
        prefix = "#{pn}. " if pn && !pn.to_s.empty?
      end
      entries = (bag.pockets[pocket] rescue nil)
      next "#{prefix}#{PokeAccess::I18n.t(:mn_close_bag)}" if entries.nil? || i >= entries.length
      itemid = entries[i][0]
      ad = win.instance_variable_get(:@adapter)
      (PokeAccess::Info.set_info(:item, itemid) rescue nil)
      (PokeAccess::Info.note_item_desc(itemid, ad.getDescription(itemid)) rescue nil) if ad && ad.respond_to?(:getDescription)
      name = (ad.getDisplayName(itemid) rescue nil) if ad
      name = (PokeAccess::Data.item_name(itemid) || itemid.to_s) if name.nil? || name.to_s.empty?
      qty = (entries[i][1] rescue nil)
      qty ? "#{prefix}#{name}: #{qty}" : "#{prefix}#{name}"
    end

    def_extractor("Window_PokemonMart") do |win, i|
      stock = win.instance_variable_get(:@stock)
      next PokeAccess::I18n.t(:pc_cancel) if i >= stock.length
      PokeAccess::Info.set_info(:item, stock[i])
      ad = win.instance_variable_get(:@adapter)
      price = (ad.getDisplayPrice(stock[i]) rescue nil)
      price ? "#{ad.getDisplayName(stock[i])}, #{price}" : ad.getDisplayName(stock[i]).to_s
    end

    def_extractor("Window_PokemonItemStorage") do |win, i|
      bag = win.instance_variable_get(:@bag)
      next PokeAccess::I18n.t(:pc_cancel) if i >= bag.length
      PokeAccess::Info.set_info(:item, bag[i][0])
      "#{win.instance_variable_get(:@adapter).getDisplayName(bag[i][0])}: #{bag[i][1]}"
    end

    # Naming grid: read the focused character, the space/switch/ok controls by name.
    def_extractor("Window_CharacterEntry") do |win, i|
      cs = win.instance_variable_get(:@charset) || []
      if i < cs.length
        c = cs[i].to_s
        c == " " ? PokeAccess::I18n.t(:key_space) : c
      elsif i == cs.length
        PokeAccess::I18n.t(:key_space)
      elsif i == cs.length + 1
        PokeAccess::I18n.t(:kb_switch)
      else
        PokeAccess::I18n.t(:kb_ok)
      end
    end

    # In-game control remap: read each action with its assigned key, plus the controls.
    def_extractor("Window_PokemonControls") do |win, i|
      controls = win.instance_variable_get(:@controls) || []
      n = controls.length
      if i == n + 1
        PokeAccess::I18n.t(:sm_exit)
      elsif i == n
        PokeAccess::I18n.t(:mn_default_keys)
      elsif controls[i]
        "#{controls[i].controlAction}: #{controls[i].keyName}"
      end
    end

    # Dual-shape: gen-6 entries are arrays ([species, name, .., displayname]) read against $Trainer; the
    # modern Window_Pokedex stores hashes ({:species, :name}) read against $player. One extractor covers both.
    def_extractor("Window_Pokedex") do |win, i|
      c = win.instance_variable_get(:@commands)[i]
      if c.is_a?(Hash)
        sp = c[:species]
        nm = c[:name]
        nm = (PokeAccess::Data.species_name(sp) || "?") if nm.nil? || nm.to_s.empty?
        seen = ($player.seen?(sp) rescue false)
        owned = ($player.owned?(sp) rescue false)
        cap = PokeAccess::I18n.t(:dex_caught); sn = PokeAccess::I18n.t(:dex_seen)
        seen ? "#{nm}, #{owned ? cap : sn}" : "#{nm}, #{PokeAccess::I18n.t(:dex_unknown)}"
      elsif c
        if $Trainer && $Trainer.seen[c[0]]
          "#{c[4]}, #{c[1]}, #{$Trainer.owned[c[0]] ? PokeAccess::I18n.t(:dex_caught) : PokeAccess::I18n.t(:dex_seen)}"
        else
          "#{c[4]}, #{PokeAccess::I18n.t(:dex_unknown)}"
        end
      else
        ""
      end
    end
  end
end

# Command-window navigation (the game changes @index directly). The first read is queued so it does not
# cut a question/title spoken just before; later navigation interrupts. Battle menus (@ignore_input) are
# skipped (they have dedicated readers); bag windows re-read on a pocket change too.
PokeAccess::Hooks.after_hook("Window_DrawableCommand", :update) do |win, _r, _a|
  next if (win.instance_variable_get(:@ignore_input) rescue false)
  idx = win.instance_variable_get(:@index)
  pkt = (win.respond_to?(:pocket) ? (win.pocket rescue nil) : nil)
  if win.active && idx && idx >= 0 &&
     (idx != win.instance_variable_get(:@access_last) || pkt != win.instance_variable_get(:@access_pocket))
    first = win.instance_variable_get(:@access_last).nil?
    win.instance_variable_set(:@access_last, idx)
    win.instance_variable_set(:@access_pocket, pkt)
    txt = PokeAccess::Menus.focused_text(win)
    PokeAccess.speak(PokeAccess.clean(txt), !first) if txt && !txt.to_s.empty?
  end
end

# Generic auto-detection (Config.auto_detect, on by default): reads navigable Window_Selectable windows
# with no dedicated reader (and not Window_DrawableCommand, covered above), by introspecting the index +
# option list (the real strings, so it cannot misread like OCR). Heavily guarded and deduped by index/pocket.
PokeAccess::Hooks.after_hook("Window_Selectable", :update) do |win, _r, _a|
  next unless (PokeAccess::Config.auto_detect rescue false)
  next if defined?(Window_DrawableCommand) && win.is_a?(Window_DrawableCommand)
  next if (win.instance_variable_get(:@ignore_input) rescue false)
  idx = (win.respond_to?(:index) ? (win.index rescue nil) : win.instance_variable_get(:@index))
  pkt = (win.respond_to?(:pocket) ? (win.pocket rescue nil) : nil)
  if (win.active rescue false) && idx && idx >= 0 &&
     (idx != win.instance_variable_get(:@access_last_auto) || pkt != win.instance_variable_get(:@access_pocket_auto))
    first = win.instance_variable_get(:@access_last_auto).nil?
    win.instance_variable_set(:@access_last_auto, idx)
    win.instance_variable_set(:@access_pocket_auto, pkt)
    txt = PokeAccess::Menus.generic_focus(win, idx)
    PokeAccess.speak(PokeAccess.clean(txt), !first) if txt && !txt.to_s.empty?
  end
end
