module PokeAccess
  # Realidea's "Vision Realidea" (SystemScene): icon menus whose cursor is a LOCAL variable inside each
  # blocking loop, so no clean hook can read it. We hold the scene during the loop (around-hook) and, since
  # the cursor never reaches an ivar, the scene's loop is left to run untouched while we speak the focused
  # option from a per-frame poll that tracks the cursor ourselves by mirroring the same key handling.
  #
  # The labels are fixed and known by position, so they come from i18n. We never reimplement the game's
  # actions: C and B fall through to the game, which owns all point spending and screen transitions. We only
  # track LEFT/RIGHT/UP/DOWN to know where the cursor is and announce it. If Realidea changes SystemScene's
  # navigation or option order, only the LISTS and the step tables below need updating.
  module RealideaSystem
    # Option labels per menu, in the game's 1-based select order.
    MAIN  = [:rl_sys_heal, :rl_sys_moves, :rl_sys_levelup, :rl_sys_magnifier, :rl_sys_repel]
    CURE  = [:rl_cure_20, :rl_cure_50, :rl_cure_80, :rl_cure_120, :rl_cure_200, :rl_cure_revive]
    MOVES = [:rl_mo_cut, :rl_mo_rocksmash, :rl_mo_flash, :rl_mo_strength, :rl_mo_fly]

    @active = nil
    @list = nil
    @sel = 1
    @last = nil
    @stack = []

    # Begins tracking a menu, saving the parent menu's state first. The menus recurse (startScene opens
    # chooseMO which reopens startScene), so a stack is needed: stopping a child must restore its parent's
    # tracking instead of leaving it muted. Resets the cursor to the game's initial value (always 1).
    def self.start(list)
      @stack.push([@active, @list, @sel, @last])
      @active = true
      @list = list
      @sel = 1
      @last = nil
    end

    # Restores the parent menu's tracking state, or clears it when no parent remains.
    def self.stop
      @active, @list, @sel, @last = @stack.pop || [nil, nil, 1, nil]
    end

    # Mirrors the scene's own wrap-around navigation and speaks the focused option when it changes. Called
    # once per frame while a menu is active. Wrapping matches the game: MAIN wraps right 5->1; the grids
    # (CURE/MOVES) clamp horizontally and step by 3 vertically.
    def self.poll
      return unless @active && @list
      max = @list.size
      if Input.trigger?(Input::RIGHT)
        @sel = (@sel < max) ? @sel + 1 : (@list.equal?(MAIN) ? 1 : @sel)
      elsif Input.trigger?(Input::LEFT)
        @sel -= 1 if @sel > 1
      elsif Input.trigger?(Input::DOWN)
        @sel += 3 if grid? && @sel + 3 <= max
      elsif Input.trigger?(Input::UP)
        @sel -= 3 if grid? && @sel - 3 >= 1
      end
      if @sel != @last
        key = @list[@sel - 1]
        PokeAccess.speak(PokeAccess::I18n.t(key), true) if key
        @last = @sel
      end
    rescue StandardError
      nil
    end

    # The grid menus step vertically by 3; the wheel (MAIN) does not.
    def self.grid?
      @list.equal?(CURE) || @list.equal?(MOVES)
    end
  end
end

PokeAccess::Game.define("realidea") do
  around("SystemScene", :startScene) do |scene, call_next, _a|
    PokeAccess::RealideaSystem.start(PokeAccess::RealideaSystem::MAIN)
    begin; call_next.call; ensure; PokeAccess::RealideaSystem.stop; end
  end
  around("SystemScene", :chooseCurar) do |scene, call_next, _a|
    PokeAccess::RealideaSystem.start(PokeAccess::RealideaSystem::CURE)
    begin; call_next.call; ensure; PokeAccess::RealideaSystem.stop; end
  end
  around("SystemScene", :chooseMO) do |scene, call_next, _a|
    PokeAccess::RealideaSystem.start(PokeAccess::RealideaSystem::MOVES)
    begin; call_next.call; ensure; PokeAccess::RealideaSystem.stop; end
  end
  poll_each_frame { PokeAccess::RealideaSystem.poll }
end
