module PokeAccess
  # Keyboard text entry (naming). With USEKEYBOARDTEXTENTRY the player types on the physical keyboard,
  # so typed/deleted characters are echoed and the mod's global keys are suppressed while a field is active.
  module TextEntry
    # Reads the character at the cursor when it moves without the text changing (pure left/right
    # navigation), so deletions/insertions are not double-read.
    def self.cursor_read(win)
      helper = win.instance_variable_get(:@helper)
      return unless helper
      cur = (helper.cursor rescue nil)
      return if cur.nil?
      txt = (helper.text rescue "")
      len = txt.scan(/./m).length
      lastcur = win.instance_variable_get(:@access_cursor)
      lastlen = win.instance_variable_get(:@access_textlen)
      if !lastcur.nil? && cur != lastcur && len == lastlen
        c = txt.scan(/./m)[cur]
        PokeAccess.speak(c.nil? ? PokeAccess::I18n.t(:te_end) : (c == " " ? PokeAccess::I18n.t(:key_space) : c), true)
      end
      win.instance_variable_set(:@access_cursor, cur)
      win.instance_variable_set(:@access_textlen, len)
    rescue StandardError
      nil
    end
  end
end

# Echo each inserted character (insert is inherited by the keyboard window).
PokeAccess::Hooks.after_hook("Window_TextEntry", :insert) do |_w, _r, args|
  PokeAccess::Keys.typing!
  c = args[0].to_s
  PokeAccess.speak(c == " " ? PokeAccess::I18n.t(:key_space) : c, true) unless c.empty?
end

# Announce deletions.
PokeAccess::Hooks.after_hook("Window_TextEntry", :delete) do |_w, _r, _a|
  PokeAccess::Keys.typing!
  PokeAccess.speak(PokeAccess::I18n.t(:te_deleted), true)
end

# Suppress mod commands while a text field updates (the keyboard subclass overrides update without super).
["Window_TextEntry_Keyboard", "Window_TextEntry"].each do |cn|
  PokeAccess::Hooks.after_hook(cn, :update) do |win, _r, _a|
    if (win.active rescue true)
      PokeAccess::Keys.typing!
      PokeAccess::TextEntry.cursor_read(win)
    end
  end
end

module PokeAccess
  # Modern cursor-mode naming (PokemonEntryScene2): an on-screen grid plus mode tabs and Back/OK, driven
  # by @cursorpos/@mode with no command window, so the generic reader never sees it. gen-6 uses
  # Window_CharacterEntry (already covered), so this hook simply does not fire there.
  module CursorNaming
    CONTROLS = { -6 => :nm_upper, -5 => :nm_lower, -4 => :nm_accents, -3 => :nm_symbols,
                 -2 => :nm_back, -1 => :nm_ok }

    # Announces the focused grid character or control on cursor/mode change, and echoes an inserted
    # character or a deletion when the entered text changes.
    def self.poll(scene)
      mode = (scene.instance_variable_get(:@mode) rescue 0)
      pos = (scene.instance_variable_get(:@cursorpos) rescue nil)
      txt = (scene.instance_variable_get(:@helper).text rescue "")
      len = txt.scan(/./m).length
      lastlen = scene.instance_variable_get(:@access_len)
      if !lastlen.nil? && len != lastlen
        c = txt.scan(/./m)[-1].to_s
        say = (len > lastlen) ? (c == " " ? PokeAccess::I18n.t(:key_space) : c) : PokeAccess::I18n.t(:te_deleted)
        PokeAccess.speak(say, true)
      elsif !pos.nil? && (pos != scene.instance_variable_get(:@access_pos) ||
                          mode != scene.instance_variable_get(:@access_mode))
        PokeAccess.speak(focus_text(scene, mode, pos), true)
      end
      scene.instance_variable_set(:@access_pos, pos)
      scene.instance_variable_set(:@access_mode, mode)
      scene.instance_variable_set(:@access_len, len)
    rescue StandardError
      nil
    end

    # The spoken label of the focused element: a control name, or the grid character at the cursor.
    def self.focus_text(scene, mode, pos)
      return PokeAccess::I18n.t(CONTROLS[pos]) if CONTROLS.key?(pos)
      chars = (scene.class.send(:class_variable_get, :@@Characters)[mode][0] rescue nil)
      c = chars ? chars[pos].to_s : ""
      c == " " ? PokeAccess::I18n.t(:key_space) : c
    end
  end
end

PokeAccess::Hooks.after_hook("PokemonEntryScene2", :pbUpdate) do |scene, _r, _a|
  (PokeAccess::Keys.typing! rescue nil)
  PokeAccess::CursorNaming.poll(scene)
end
