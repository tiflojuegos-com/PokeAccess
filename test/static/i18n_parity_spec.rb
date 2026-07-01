# i18n parity over the real lang/ files: every key present in all languages, no key duplicated within a
# file, and matching %{var} placeholders across languages -- any of those breaks a string in one language
# (the usual cause of an English line in a Spanish game). Unlike the runner's non-failing parity warning,
# this spec asserts the issue list is empty, so a release with a drifted string fails CI.
Suite.define("i18n: lang/ files are in parity (keys, duplicates, placeholders)") do
  issues = (PokeAccess::I18n.parity_issues rescue ["parity check raised"])
  eq "no parity issues across language files", issues, []
end
