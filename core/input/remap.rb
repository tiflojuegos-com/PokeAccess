module PokeAccess
  # Optional key remapper: tracks how long each bound key has been held and feeds that into the engine's
  # input. Two action kinds -- base RPG Maker buttons and game extras bound to a raw virtual-key
  # (registered via register_extra). A rebound action silences the engine's default key, except directions
  # (kept additive so movement stays safe). Every addition is rescued, so a bug here can't take control away.
  module Remap
    REPEAT_DELAY = 15
    REPEAT_INTERVAL = 6

    # Base buttons: [action symbol, Input constant name, label key].
    BUTTONS = [
      [:down,  :DOWN,  :btn_down],
      [:left,  :LEFT,  :btn_left],
      [:right, :RIGHT, :btn_right],
      [:up,    :UP,    :btn_up],
      [:c,     :C,     :btn_accept],
      [:b,     :B,     :btn_cancel],
      [:a,     :A,     :btn_a],
      [:x,     :X,     :btn_x],
      [:y,     :Y,     :btn_y],
      [:z,     :Z,     :btn_z],
      [:l,     :L,     :btn_l],
      [:r,     :R,     :btn_r]
    ]
    DIR_CODE = { :up => 8, :down => 2, :left => 4, :right => 6 }
    @held = {}

    # The registry of game extras: action symbol => [default virtual-key, label].
    def self.extras; @extras ||= {}; end

    # Registers a game-specific action read by raw virtual-key, so it can be rebound from the remap menu.
    def self.register_extra(sym, default_vk, label)
      extras[sym] = [default_vk, label]
    end

    # The full remap-menu action list: base buttons, game extras, and a final reset-all entry.
    # Built on a duped array with concat/push, never BUTTONS + [...]: Pokemon Z's MTS library
    # redefines Array#+ as an in-place mutator, so the literal `+` would corrupt the constant.
    def self.buttons
      list = BUTTONS.dup
      list.concat(extras.map { |sym, info| [sym, nil, info[1]] })
      list.push([:__reset__, nil, :btn_reset_all])
      list
    end

    #labels and lookups

    # action symbol => Input button integer, resolved once (Input.const_get is costly per-frame).
    def self.btn_int_map
      @btn_int_map ||= begin
        m = {}
        BUTTONS.each { |row| c = (Input.const_get(row[1]) rescue nil); m[row[0]] = c unless c.nil? }
        m
      end
    end

    # The reverse map: Input button integer => action symbol, resolved once.
    def self.int_sym_map
      @int_sym_map ||= begin
        m = {}; btn_int_map.each { |sym, i| m[i] = sym }; m
      end
    end

    # Spoken label for an action (a per-game override wins); resolved through I18n, where an unknown
    # key returns itself.
    def self.label(sym)
      raw = (PokeAccess::Config.rebind_labels[sym] rescue nil) ||
            (BUTTONS.assoc(sym)[2] rescue nil) ||
            (extras[sym] && extras[sym][1]) || sym.to_s
      PokeAccess::I18n.t(raw)
    end

    # The base action bound to an Input button integer, if any.
    def self.sym_for_button(bi); int_sym_map[bi]; end

    # The extra action whose default key is this raw virtual-key, if any.
    def self.sym_for_extra(vk)
      extras.each { |sym, info| return sym if info[0] == vk }
      nil
    end

    #per-frame polling

    # Updates how long each bound key has been held; call once per frame.
    def self.update
      g = PokeAccess::Keys::GAKS
      return unless g
      unless (PokeAccess::Keys.enabled rescue true) && (PokeAccess::Keys.focused? rescue true)
        @held = {}
        return
      end
      binds = (PokeAccess::Config.rebinds rescue nil)
      if binds.nil? || binds.empty?
        @held = {} unless @held.empty?
        return
      end
      @held.each_key { |s| @held[s] = 0 unless binds.key?(s) }
      binds.each do |sym, code|
        next unless code
        down = (g.call(code) & 0x8000) != 0
        @held[sym] = down ? (@held[sym].to_i + 1) : 0
      end
    end

    # True while the bound key for an action is held.
    def self.pressed_sym?(sym); (@held[sym] || 0) > 0; end

    # True only on the frame the bound key for an action transitions to pressed.
    def self.triggered_sym?(sym); (@held[sym] || 0) == 1; end

    # True on press and then on the repeat schedule, for menu navigation.
    def self.repeated_sym?(sym)
      h = @held[sym] || 0
      h == 1 || (h > REPEAT_DELAY && ((h - REPEAT_DELAY) % REPEAT_INTERVAL) == 0)
    end

    #base-button queries (by Input integer)

    def self.pressed?(bi);   s = sym_for_button(bi); s ? pressed_sym?(s)   : false; end
    def self.triggered?(bi); s = sym_for_button(bi); s ? triggered_sym?(s) : false; end
    def self.repeated?(bi);  s = sym_for_button(bi); s ? repeated_sym?(s)  : false; end

    # True if a non-direction base button is bound, so its hook uses only the bound key and lets the
    # engine's default key go silent (directions are never suppressed; a missing GAKS can't lock input).
    def self.remapped_button?(bi)
      return false unless PokeAccess::Keys::GAKS
      s = sym_for_button(bi)
      return false if s.nil? || DIR_CODE.has_key?(s)
      !(PokeAccess::Config.rebinds[s] rescue nil).nil?
    end

    # The 4-direction code from bound movement keys, or 0 if none held.
    def self.dir
      DIR_CODE.each_key { |sym| return DIR_CODE[sym] if pressed_sym?(sym) }
      0
    end

    #extra queries (by raw virtual-key)

    # True if the extra action for this raw key is bound, so triggerex? uses only the bound key.
    def self.extra_remapped?(vk)
      return false unless PokeAccess::Keys::GAKS
      s = sym_for_extra(vk)
      return false if s.nil?
      !(PokeAccess::Config.rebinds[s] rescue nil).nil?
    end

    def self.extra_triggered?(vk); s = sym_for_extra(vk); s ? triggered_sym?(s) : false; end
    def self.extra_pressed?(vk);   s = sym_for_extra(vk); s ? pressed_sym?(s)   : false; end
  end
end

# Input hooks: feed our bindings into the engine's, rescued so they can never break input. Each wrapper
# forwards *args/*rest to the original so it matches whatever signature the base uses -- La Base de Sky's
# dir4/dir8 take an argument while vanilla Essentials' take none, so a fixed arity here crashed Sky games.
begin
  class << Input
    unless method_defined?(:trigger__access_orig)
      alias_method :trigger__access_orig, :trigger?
      def trigger?(n, *rest)
        if (PokeAccess::Remap.remapped_button?(n) rescue false)
          (PokeAccess::Remap.triggered?(n) rescue false)
        else
          trigger__access_orig(n, *rest) || (PokeAccess::Remap.triggered?(n) rescue false)
        end
      end
      alias_method :press__access_orig, :press?
      def press?(n, *rest)
        if (PokeAccess::Remap.remapped_button?(n) rescue false)
          (PokeAccess::Remap.pressed?(n) rescue false)
        else
          press__access_orig(n, *rest) || (PokeAccess::Remap.pressed?(n) rescue false)
        end
      end
      alias_method :repeat__access_orig, :repeat?
      def repeat?(n, *rest)
        if (PokeAccess::Remap.remapped_button?(n) rescue false)
          (PokeAccess::Remap.repeated?(n) rescue false)
        else
          repeat__access_orig(n, *rest) || (PokeAccess::Remap.repeated?(n) rescue false)
        end
      end
      alias_method :dir4__access_orig, :dir4
      def dir4(*args); d = dir4__access_orig(*args); d != 0 ? d : (PokeAccess::Remap.dir rescue 0); end
      alias_method :dir8__access_orig, :dir8
      def dir8(*args); d = dir8__access_orig(*args); d != 0 ? d : (PokeAccess::Remap.dir rescue 0); end
    end

    #raw-key hooks for game extras, only if the engine exposes them.
    if method_defined?(:triggerex?) && !method_defined?(:triggerex__access_orig)
      alias_method :triggerex__access_orig, :triggerex?
      def triggerex?(k, *rest)
        if (PokeAccess::Remap.extra_remapped?(k) rescue false)
          (PokeAccess::Remap.extra_triggered?(k) rescue false)
        else
          triggerex__access_orig(k, *rest) || (PokeAccess::Remap.extra_triggered?(k) rescue false)
        end
      end
    end
    if method_defined?(:pressex?) && !method_defined?(:pressex__access_orig)
      alias_method :pressex__access_orig, :pressex?
      def pressex?(k, *rest)
        if (PokeAccess::Remap.extra_remapped?(k) rescue false)
          (PokeAccess::Remap.extra_pressed?(k) rescue false)
        else
          pressex__access_orig(k, *rest) || (PokeAccess::Remap.extra_pressed?(k) rescue false)
        end
      end
    end
  end
rescue StandardError => e
  PokeAccess.write_marker("hook_input_remap: #{e.message}\n")
end
