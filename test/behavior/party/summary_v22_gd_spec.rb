# Regression: in the v22 summary you cycle Pokemon in place (up/down) via set_party_index, which changes the
# shown Pokemon and then calls refresh INTERNALLY. Because hooks chain as an onion, refresh's after-hook would
# otherwise run INSIDE set_party_index (before set_party_index's own after-hook), speak the page WITHOUT the
# glance and consume the [page, party_index] dedup, leaving set_party_index's with-glance branch dead -- the
# page read without ever saying which Pokemon it belonged to. The hook engine's reentrancy guard now skips
# that nested refresh (a different method than set_party_index), so set_party_index's after-hook voices the
# switch WITH the glance.
Suite.define("summary v22: switching Pokemon announces the new Pokemon's glance") do
  party = [Poke.build(:name => "Bulba", :species => 1, :level => 12, :hp => 22, :totalhp => 22),
           Poke.build(:name => "Char",  :species => 4, :level => 25, :hp => 33, :totalhp => 44)]
  vis = UI::PokemonSummaryVisuals.new(party, 0)

  SpeakCapture.clear
  vis.set_party_index(1)
  spoke "switching reads the new Pokemon's glance (name + HP fraction)", /Char/
  spoke "the glance HP fraction is spoken (only the glance voices it)", /33 (de|of) 44/

  SpeakCapture.clear
  vis.set_party_index(0)
  spoke "switching back reads the other Pokemon's glance", /Bulba/
  spoke "the second switch is not swallowed by the earlier dedup", /22 (de|of) 22/
end

# The glance must prefix ONLY a Pokemon switch: a page change (go_to_next_page also calls refresh, which the
# guard skips) reads the page through go_to_next_page's own after-hook, with with_pkmn=false, so no stale
# Pokemon name is prepended.
Suite.define("summary v22: a page change after a switch does not prepend a glance") do
  party = [Poke.build(:name => "Squir", :species => 7, :level => 30, :hp => 55, :totalhp => 60)]
  vis = UI::PokemonSummaryVisuals.new(party, 0)
  vis.set_party_index(0)

  SpeakCapture.clear
  vis.go_to_next_page(:skills)
  spoke "the page change is read", /55 (de|of) 60/
  not_spoke "page navigation does not prepend the Pokemon glance (name)", /Squir/
end
