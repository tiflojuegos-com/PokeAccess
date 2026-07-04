# Realidea's start-of-game character/gender selection (script "Seleccion Personajes" -> class
# PokemonGenderSelection, a BW2-style picture chooser, no command window). @select is the cursor: 1 = the
# neutral start, 2 = boy, 4 = girl (RIGHT picks boy, LEFT picks girl; C confirms, going to 3/5 whose
# "¿Seguro?" the dialogue hook reads). input() runs every frame, so read @select there, deduped.
module PokeAccess
  module RealideaGender
    LABELS = {
      1 => "Selección de personaje. Derecha para chico, izquierda para chica.",
      2 => "Chico",
      4 => "Chica"
    }
  end
end

PokeAccess::Game.define("realidea") do
  after("PokemonGenderSelection", :input) do |scr, _ret, _args|
    sel = PokeAccess.ivar(scr, :@select)
    if PokeAccess::Cursor.changed?(scr, :gsel, sel)
      lbl = PokeAccess::RealideaGender::LABELS[sel]
      PokeAccess.speak(lbl, true) if lbl && !lbl.to_s.empty?
    end
  end
end
