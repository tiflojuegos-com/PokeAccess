# Pokemon Armonia constants: vanilla Essentials 16.3, the same gen-6 base as the core defaults, so this
# only relabels the field button the remap menu shows (everything generic is already covered by core).
# Armonia maps the DexNav to the X field button; relabel it in the remap menu (merged, additive).
PokeAccess::Game.define("armonia") do
  button_labels :x => "DexNav"
end
