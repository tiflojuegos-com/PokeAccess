module PokeAccess
  # Strips Essentials control codes and HTML-like tags for natural speech. The player-name code (\PN)
  # is substituted first, before the generic \X stripper would eat it. Control bytes \x00-\x1f (e.g. \1
  # "wait for input", \2 wait-time) are removed too: they are not speakable, and leaving them in makes the
  # same line differ from its non-paused twin and slip past say_dialogue's dedup -> double battle messages.
  def self.clean(message)
    t = message.to_s.dup
    t.gsub!(/\r?\n/, " ")
    pname = (($player.name rescue nil) || ($Trainer.name rescue nil) || "").to_s
    t.gsub!(/\\[Pp][Nn]/) { pname } rescue nil
    t.gsub!(/\\[Vv]\[(\d+)\]/) { $game_variables ? $game_variables[$1.to_i].to_s : "" } rescue nil
    t.gsub!(/\\[Nn]/, " ")
    t.gsub!(/\\[Cc]\[\d+\]/, "")
    t.gsub!(/\\[A-Za-z]+\[[^\]]*\]/, "")
    t.gsub!(/\\[A-Za-z]+/, "")
    t.gsub!(/\\[.!|^<>~\\]/, "")
    t.gsub!(/<\/?[A-Za-z][^>]*>/, "")
    t.gsub!(/\|/, " ")
    t.gsub!(/[\x00-\x1f]/, " ")
    t.gsub!(/\s+/, " ")
    t.strip
  end
end
