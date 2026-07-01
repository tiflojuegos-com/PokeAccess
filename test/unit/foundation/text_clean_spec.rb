# Text cleaning for speech: clean strips Essentials control codes (\c[n], \v[n], \PN...) and HTML-like
# tags, collapses whitespace, and removes the non-speakable control bytes (\x00-\x1f) whose presence makes a
# paused line differ from its twin and slip past say_dialogue's dedup (the double-battle-message bug).
Suite.define("text: clean strips control codes and markup") do
  out = PokeAccess.clean("\\c[3]Hola\\v[1] <b>mundo</b>")
  truthy "no control codes or tags remain", out && out !~ /\\c|\\v|<b>/

  vout = PokeAccess.clean("HP \\v[5] restante")
  $game_variables[5] = 42
  eq "\\v[n] interpolates the game variable", PokeAccess.clean("HP \\v[5] restante"), "HP 42 restante"

  eq "html tags are removed but the inner text stays",
     PokeAccess.clean("Usa <ar>Surf</ar> aqui"), "Usa Surf aqui"
  eq "control bytes and newlines collapse to one space",
     PokeAccess.clean("uno\ndos\x01tres"), "uno dos tres"
  eq "blank input cleans to empty", PokeAccess.clean(nil), ""
end
