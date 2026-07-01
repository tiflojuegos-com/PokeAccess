module PokeAccess
  # Triggers for the classic modern summary scene (PokemonSummary_Scene, used by v21.1 and the Sky fork).
  # All spoken content is the agnostic SummaryGameData; this file only wires this scene's hooks and dedups.
  module SummaryV21
    # Speaks a page on arrival, deduped per scene instance: drawPage is also called on every ribbon cursor
    # move, which would otherwise repeat "Cintas: N" continuously. A page change yields different text, so
    # navigating pages still reads each one; a fresh scene (reopen) reads even the same page.
    def self.speak_page(scene, page)
      t = PokeAccess::SummaryGameData.page_text(scene, page)
      return if t.nil? || t.to_s.empty?
      return if t == (scene.instance_variable_get(:@access_page_text) rescue nil)
      scene.instance_variable_set(:@access_page_text, t)
      PokeAccess.speak(t, false)
    rescue StandardError
      nil
    end
  end
end

# Each summary page read on arrival (drawPage dispatches all pages), deduped so the ribbon page (redrawn
# per cursor move) does not repeat.
PokeAccess::Hooks.after_hook("PokemonSummary_Scene", :drawPage) do |scene, _r, args|
  PokeAccess::SummaryV21.speak_page(scene, args[0])
end

# Focused move detail while navigating the moves page (and while choosing one to replace).
PokeAccess::Hooks.after_hook("PokemonSummary_Scene", :drawSelectedMove) do |scene, _r, args|
  pk = (scene.instance_variable_get(:@pokemon) rescue nil)
  PokeAccess.speak(PokeAccess::SummaryGameData.move_detail(pk, args[1]), true)
end

# Choosing which move to forget when learning a new one: list the current four.
PokeAccess::Hooks.before_hook("PokemonSummary_Scene", :pbChooseMoveToForget) do |scene, _args|
  pk = (scene.instance_variable_get(:@pokemon) rescue nil)
  PokeAccess.speak(PokeAccess::I18n.t(:sm_choose_forget) + ". " + PokeAccess::SummaryGameData.moves_text(pk).to_s, false)
end
