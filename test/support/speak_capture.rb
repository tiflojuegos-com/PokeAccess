# Records what the mod would speak, instead of driving the screen-reader DLL. It redefines PokeAccess.speak
# to run the REAL PokeAccess.clean (where control-code and double-speak bugs live) and append the cleaned
# line plus its interrupt flag to a log, so behaviour specs can assert on the spoken text.
module SpeakCapture
  @log = []

  # Replaces PokeAccess.speak with the recording version. Call once after the toolkit is loaded.
  def self.install
    log = @log
    PokeAccess.define_singleton_method(:speak) do |text, interrupt = true|
      t = PokeAccess.clean(text)
      next if t.to_s.empty?
      @last_spoken = t
      log.push([t, interrupt])
      nil
    end
  end

  # Empties the log (the runner calls this before each suite).
  def self.clear
    @log.clear
  end

  # The raw log of [text, interrupt] pairs since the last clear.
  def self.log
    @log
  end

  # Just the spoken texts since the last clear.
  def self.lines
    @log.map { |t, _| t }
  end

  # The last spoken text, or nil.
  def self.last
    (@log.last || [])[0]
  end
end
