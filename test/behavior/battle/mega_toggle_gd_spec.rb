# Modern-path regression: in v21 the fight menu opens via setIndexAndMode, which assigns @mode DIRECTLY
# without going through the mode= setter, so the mode= hook never sees the open. Before the fix, @access_mega
# stayed nil and the FIRST real Mega-Evolution toggle of every battle was swallowed (mega_key(nil, 2) => nil).
# The setIndexAndMode hook must prime @access_mega from the opening mode so the open stays muted and the first
# available(1)->registered(2) toggle is voiced. Runs only in the gamedata engine pass (the fork/vanilla v21
# Battle::Scene is stubbed there); gen-6 uses FightMenuDisplay and is covered separately.
Suite.define("battle (gamedata): first v21 mega toggle sounds after opening via setIndexAndMode") do
  menu = ::Battle::Scene::FightMenu.new
  menu.setIndexAndMode(0, 1)
  not_spoke "opening the fight menu does not announce a mega toggle",
            /#{Regexp.escape(PokeAccess::I18n.t(:bt_mega_on))}|#{Regexp.escape(PokeAccess::I18n.t(:bt_mega_off))}/
  eq "the open primes the mega state from the opening mode", menu.instance_variable_get(:@access_mega), 1
  menu.mode = 2
  spoke "the first toggle to registered is announced",
        /#{Regexp.escape(PokeAccess::I18n.t(:bt_mega_on))}/
end

# The open with mega hidden (mode 0) primes nothing, and a later reveal is still not spoken (it is not a
# toggle), but the toggle after it is -- so the guard both stays quiet on the open and never over-announces.
Suite.define("battle (gamedata): mega toggle still deactivates on the second press") do
  menu = ::Battle::Scene::FightMenu.new
  menu.setIndexAndMode(0, 1)
  menu.mode = 2
  SpeakCapture.clear
  menu.mode = 1
  spoke "toggling back to available is announced as off",
        /#{Regexp.escape(PokeAccess::I18n.t(:bt_mega_off))}/
end
