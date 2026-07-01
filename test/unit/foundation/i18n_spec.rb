# i18n by symbolic key: t reads the active language, falls back to the key name when absent, interpolates
# %{var} placeholders, and reports the languages with a lang/*.txt file. The English values are checked
# against en.txt; the Spanish side is checked only as "present and different", never against a literal.
Suite.define("i18n: lookup, fallback, interpolation, available languages") do
  PokeAccess::Config.language = :en
  eq "english value from en.txt", PokeAccess::I18n.t(:cfg_saved), "Settings saved"
  eq "missing key falls back to the key name",
     PokeAccess::I18n.t(:clave_inexistente_xyz), "clave_inexistente_xyz"
  eq "interpolation fills placeholders",
     PokeAccess::I18n.t(:loc_count, :n => 3, :total => 9), "3 of 9"

  PokeAccess::Config.language = :es
  truthy "spanish entry exists and differs from english",
         PokeAccess::I18n.t(:cfg_saved) != "Settings saved" && !PokeAccess::I18n.t(:cfg_saved).empty?
  truthy "es and en are both available",
         PokeAccess::I18n.available_languages.include?(:es) &&
         PokeAccess::I18n.available_languages.include?(:en)
  PokeAccess::Config.language = :es
end
