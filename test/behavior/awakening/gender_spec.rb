# Awakening's player gender pick (PokemonGenderSelection) is two text-less sprites; @select 2/3 = boy,
# 4/5 = girl, 1 = none. The reader holds the live instance (its loop blocks in initialize) and speaks the
# focused gender from @select on each poll, deduped. The runner loads the pokemon_z profile, so this spec
# pulls in the awakening reader itself (it only needs the module, not the game's classes).
require File.expand_path("../../../games/awakening/gender", File.dirname(__FILE__))

Suite.define("awakening: gender selection speaks boy/girl from @select") do
  g = Object.new
  PokeAccess::AwakeningGender.watch(g)

  g.instance_variable_set(:@select, 1); PokeAccess::AwakeningGender.poll
  silent "the initial (no-choice) state says nothing"

  g.instance_variable_set(:@select, 2); PokeAccess::AwakeningGender.poll
  spoke "left selects boy", /#{PokeAccess::I18n.t(:aw_gender_boy)}/

  SpeakCapture.clear
  g.instance_variable_set(:@select, 4); PokeAccess::AwakeningGender.poll
  spoke "right selects girl", /#{PokeAccess::I18n.t(:aw_gender_girl)}/

  SpeakCapture.clear
  g.instance_variable_set(:@select, 4); PokeAccess::AwakeningGender.poll
  silent "an unchanged cursor stays silent (dedup)"

  PokeAccess::AwakeningGender.unwatch
end
