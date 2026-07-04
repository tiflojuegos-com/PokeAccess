module PokeAccess
  # Realidea's text log (Kyu's TextLog, opened with F): a scrollable history of past messages in
  # $PokemonGlobal.log (an array of message line-arrays), all drawn to a bitmap. drawLines redraws the page
  # on open and on each scroll, advancing @pos past the entries it drew; the entry that just became the
  # current one is at @pos-1. Read that entry (its lines joined and cleaned) when @pos changes.
  module RealideaTextLog
    # The index into $PokemonGlobal.log of the most recently focused entry (@pos-1), clamped to the array
    # bounds, or nil if there is no log. Dedup uses this rather than raw @pos so scrolling against either
    # end (where @pos changes but the focused entry does not) does not re-read the same line.
    def self.focus_index(scene)
      pos = PokeAccess.ivar(scene, :@pos)
      log = ($PokemonGlobal.log rescue nil)
      return nil if pos.nil? || !log.is_a?(Array) || log.empty?
      i = pos - 1
      i = 0 if i < 0
      i = log.length - 1 if i > log.length - 1
      i
    end

    # The log entry at the given index as a single cleaned string, or nil.
    def self.entry_text(i)
      log = ($PokemonGlobal.log rescue nil)
      return nil if i.nil? || !log.is_a?(Array) || i < 0 || i >= log.length
      entry = log[i]
      raw = entry.is_a?(Array) ? entry.join(" ") : entry.to_s
      PokeAccess.clean(raw)
    rescue StandardError
      nil
    end

    # Reads the focused log entry when the focused index changes.
    def self.announce(scene)
      i = focus_index(scene)
      return if i == scene.instance_variable_get(:@access_log_pos)
      scene.instance_variable_set(:@access_log_pos, i)
      t = entry_text(i)
      PokeAccess.speak(t, true) if t && !t.to_s.empty?
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("realidea") do
  after("Log", :drawLines) { |scene, _result, _args| PokeAccess::RealideaTextLog.announce(scene) }
end
