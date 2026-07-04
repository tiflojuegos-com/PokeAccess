# Regression: in the gen-6 summary you can cycle Pokemon in place (up/down) without leaving, and the info
# key (T) must read the Pokemon currently SHOWN. Before the fix only the party slot set the contextual
# Pokemon, so T kept reading the one you entered with. pbUpdate now refreshes Info.set_info(:pokemon).
Suite.define("summary gen-6: info key follows the shown Pokemon") do
  scene = World.summary_scene(:pokemon => Poke.build(:name => "Bulba", :species => 1))
  scene.pbUpdate
  info = PokeAccess::Info.info_text
  match "T reads the entered Pokemon", info, /Bulba/

  scene.pokemon = Poke.build(:name => "Char", :species => 4)
  scene.pbUpdate
  info2 = PokeAccess::Info.info_text
  match "T reads the NEW Pokemon after switching", info2, /Char/
  not_spoke_label = info2.to_s.include?("Bulba")
  eq "T no longer reads the old Pokemon", not_spoke_label, false
end

# Regression (reentrancy guard must not silence the open): pbStartScene has a before-hook (reset_reorder)
# and its original draws the first page synchronously (drawPage -> drawPageOne), whose after-hook reads the
# data sheet. When the guard was pushed on the before path, :pbStartScene sat on the active stack for the
# whole open, so the nested drawPageOne (a different method) was skipped and the sheet was never read: the
# player opened the summary and heard nothing about which Pokemon it was until pressing left/right. The
# guard now lives on the after path only, so the open reads the sheet.
Suite.define("summary gen-6: opening the summary reads the data sheet") do
  scene = World.summary_scene(:pokemon => Poke.build(:name => "Bulba", :species => 1))
  SpeakCapture.clear
  scene.pbStartScene([Poke.build(:name => "Bulba", :species => 1)], 0)
  spoke "the full data sheet is read on open", /Bulba/
end
