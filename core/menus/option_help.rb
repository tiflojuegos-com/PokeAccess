# Per-option help. The Options scene draws each option's description into @sprites["textbox"] on
# selection change; the name/value are read by the command-window extractor, so the description is
# offered on the info key (read on demand). Covers both engine scene names; no-op where absent.
["PokemonOption_Scene", "PokemonOptionScene", "PokemonOptionPuntos_Scene"].each do |cn|
  PokeAccess::Hooks.after_hook(cn, :pbChangeSelection) do |scene, _r, _a|
    tb = ((scene.instance_variable_get(:@sprites) || {})["textbox"] rescue nil)
    d = (tb.text rescue nil)
    PokeAccess::Info.set_info(:text, PokeAccess.clean(d)) if d && !d.to_s.strip.empty?
  end
end
