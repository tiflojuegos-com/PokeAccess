module PokeAccess
  # The multi-save "other save files" screen (PScreen_Load): a panel + moving-cursor selector
  # (pbMoveSaveSel slides an icon over pre-drawn rows), not a command window, so the generic reader never
  # sees it. Announces the focused save file as the cursor moves, and the first one on open.
  module LoadScreen
    # The spoken label of a save-file row (its display name at savefiles[i][1]).
    def self.savefile_text(files, idx)
      return nil unless files.is_a?(Array) && files[idx].is_a?(Array)
      nm = files[idx][1]
      (nm && !nm.to_s.empty?) ? nm.to_s : nil
    rescue StandardError
      nil
    end
  end
end

# Opening the list: announce the first row without interrupting the title music/voice.
PokeAccess::Hooks.after_hook("PokemonLoadScene", :pbDrawSaveCommands) do |_s, _r, args|
  txt = PokeAccess::LoadScreen.savefile_text(args[0], 0)
  PokeAccess.speak(PokeAccess.clean(txt), false) if txt
end

# Moving the cursor: announce the now-focused save file, interrupting the previous one.
PokeAccess::Hooks.after_hook("PokemonLoadScene", :pbMoveSaveSel) do |scene, _r, args|
  files = scene.instance_variable_get(:@savefiles)
  txt = PokeAccess::LoadScreen.savefile_text(files, args[0])
  PokeAccess.speak(PokeAccess.clean(txt), true) if txt
end
