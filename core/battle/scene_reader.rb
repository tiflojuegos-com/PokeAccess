module PokeAccess
  # Engine-agnostic reader for the modern Battle::Scene menus. The command, fight and target menus are
  # Battle::Scene::MenuBase subclasses that hold the selection in @index with graphic labels, so the focused
  # option is read by introspection. These classes are shared across Essentials v19-v22 vanilla (and the Sky
  # fork), so this reader is version-neutral: the v21 and v22 files own only the hooks that TRIGGER it (each
  # engine opens/navigates its menus differently), while the spoken content lives here once. On gen-6 there
  # is no Battle::Scene, so nothing here is ever reached (its triggers never bind).
  module BattleScene
    # The first three command buttons are fixed; the fourth depends on the menu mode. Labels are i18n keys.
    # Used on v19-v21, whose command menu is position-based.
    CMD_LABELS = [:bt_cmd_fight, :bt_cmd_bag, :bt_cmd_pokemon]
    CMD3 = { 0 => :bt_cmd_run, 1 => :pc_cancel, 2 => :bt_cmd_call, 3 => :bt_cmd_run, 4 => :bt_cmd_run }
    # v22's command menu is symbol-based and reorderable, so the focused option is read from the symbol
    # (menu.command) rather than by position.
    CMD_SYMS = { :fight => :bt_cmd_fight, :fight2 => :bt_cmd_fight, :bag => :bt_cmd_bag,
                 :pokemon => :bt_cmd_pokemon, :run => :bt_cmd_run, :call => :bt_cmd_call,
                 :cancel => :pc_cancel, :shift => :bt_shift }

    # Reads the focused option of a battle menu, dispatching on its kind; a no-op for kinds not
    # special-cased. param interrupt whether this read may cut current speech (true for navigation; false
    # on open, so it does not cut the hp/turn lines just spoken)
    def self.read_menu(menu, interrupt = true)
      t = nil; foe = false
      if defined?(::Battle::Scene::CommandMenu) && menu.is_a?(::Battle::Scene::CommandMenu)
        t = command_label(menu); foe = true
      elsif defined?(::Battle::Scene::FightMenu) && menu.is_a?(::Battle::Scene::FightMenu)
        m = fight_move(menu)
        t = move_text(m, (menu.battler rescue nil)) if m
      elsif defined?(::Battle::Scene::TargetMenu) && menu.is_a?(::Battle::Scene::TargetMenu)
        t = target_label(menu)
      end
      if t && !t.to_s.empty?
        foe ? PokeAccess::Info.set_info(:battle_foe, nil) : PokeAccess::Info.set_info(:text, t)
        PokeAccess.speak(t, interrupt)
      end
    rescue StandardError => e
      PokeAccess.log_once("battlescene_read", e)
    end

    # The focused command name (Luchar/Mochila/Pokemon...). Prefer the menu's own button texts (@texts),
    # which the engine and battle plugins fill via setTexts -- this reads the real labels shown, including
    # extra buttons a kit like DBK adds (Dynamax/Tera/Z-Move). Falls back to the v22 command symbol
    # (menu.command), then to the v19-v21 fixed positions with a mode-dependent fourth button.
    def self.command_label(menu)
      idx = (menu.index rescue 0)
      texts = (menu.instance_variable_get(:@texts) rescue nil)
      return PokeAccess.clean(texts[idx]) if texts.is_a?(Array) && idx && texts[idx] && !texts[idx].to_s.empty?
      sym = (menu.command rescue nil)
      return PokeAccess::I18n.t(CMD_SYMS[sym] || sym.to_s) if sym.is_a?(Symbol)
      return PokeAccess::I18n.t(CMD_LABELS[idx]) if idx && idx < 3
      mode = (menu.mode rescue 0)
      PokeAccess::I18n.t(CMD3[mode] || :bt_cmd_run)
    end

    # The move object under the fight cursor.
    def self.fight_move(menu)
      b = (menu.battler rescue nil)
      return nil unless b
      idx = (menu.index rescue 0)
      (b.moves[idx] rescue nil)
    end

    # The focused target's name in the target menu. The menu's @texts is indexed by battler index; in
    # double battles the engine may leave a slot blank (a hidden/unseen foe), which previously read as
    # silence -- so when @texts[idx] is empty, name the battler at that index directly (pbThis, or a
    # positional fallback) so every target is announced.
    def self.target_label(menu)
      texts = (menu.instance_variable_get(:@texts) rescue nil)
      idx = (menu.index rescue 0)
      t = (texts && texts[idx] && !texts[idx].to_s.empty?) ? PokeAccess.clean(texts[idx]) : nil
      return t if t
      b = (PokeAccess::Battle.battler_at(idx) rescue nil)
      if b
        nm = (b.pbThis rescue nil)
        nm = (b.name rescue nil) if nm.nil? || nm.to_s.empty?
        return PokeAccess.clean(nm) if nm && !nm.to_s.empty?
      end
      idx ? PokeAccess::I18n.t(:bt_target_n, :n => idx + 1) : nil
    end

    # Describes a battle move: name, type, power, accuracy and pp, from the modern move object. param
    # battler the battler using it (for the in-battle type), may be nil
    def self.move_text(move, battler)
      return nil unless move
      nm = (move.name rescue nil); nm = PokeAccess::I18n.t(:info_move) if nm.nil? || nm.to_s.empty?
      tsym = (battler ? move.display_type(battler) : move.type) rescue (move.type rescue nil)
      ty = (GameData::Type.get(tsym).name rescue nil)
      pp = (move.pp rescue nil); tot = (move.total_pp rescue nil)
      PokeAccess::MoveInfo.line(nm.to_s, ty, (move.power rescue 0), (move.accuracy rescue 0), :pp => pp, :total_pp => tot)
    rescue StandardError
      (move.name rescue PokeAccess::I18n.t(:info_move))
    end

    # The ability-trigger cue: which battler's ability activated. With the ability splash on (the default)
    # this is shown only as a graphic, so a blind player would miss it; off, the effect message already
    # names the ability and the scene splash method is not called, so no double-read.
    def self.ability_text(battler)
      return nil unless battler
      nm = (battler.pbThis rescue nil); ab = (battler.abilityName rescue nil)
      return nil if ab.nil? || ab.to_s.empty?
      PokeAccess::I18n.t(:bt_ability, :name => nm, :ability => ab)
    rescue StandardError
      nil
    end

    # Spoken hp delta for a battler: the player's own pokemon read exact hp, the foe as a percentage
    # (parity with what the bars reveal). param lost true for damage, false for healing
    def self.hp_change_text(battler, amt, lost)
      return nil unless battler && amt && amt.to_i > 0
      foe = (battler.opposes? rescue false)
      verb = PokeAccess::I18n.t(lost ? :bt_lose : :bt_gain)
      rest = if foe
               tot = (battler.totalhp rescue 0).to_i
               PokeAccess::I18n.t(:bt_hp_pct, :n => (tot > 0 ? battler.hp.to_i * 100 / tot : 0))
             else
               PokeAccess::I18n.t(:bt_hp_exact, :hp => battler.hp, :tot => battler.totalhp)
             end
      PokeAccess::I18n.t(:bt_hp_change, :name => battler.name, :verb => verb, :n => amt.to_i, :rest => rest)
    rescue StandardError
      nil
    end
  end
end
