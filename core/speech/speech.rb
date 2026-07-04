module PokeAccess
  # Voice constants (SRAL drives NVDA/JAWS/SAPI/Narrator/ZDSR; UTF-8 direct).
  (Win32API.new("kernel32", "SetDllDirectoryA", ["p"], "i").call(DLL_DIR + "\0") rescue nil)
  SRAL_INIT  = (Win32API.new("SRAL.dll", "SRAL_Initialize", ["i"],      "i") rescue nil)
  SRAL_SPEAK = (Win32API.new("SRAL.dll", "SRAL_Speak",      ["p", "i"], "i") rescue nil)
  @ready = false

  # Speaks text through the active screen reader. param interrupt true cuts current speech, false queues.
  def self.speak(text, interrupt = true)
    return unless SRAL_SPEAK
    unless @ready
      SRAL_INIT.call(0) if SRAL_INIT
      @ready = true
    end
    text = text.to_s.gsub(/\s+/, " ").strip
    return if text.empty?
    @last_spoken = text
    SRAL_SPEAK.call(text + "\0", interrupt ? 1 : 0)
  rescue StandardError => e
    write_marker("speak_error: #{format_error(e)}\n")
  end

  # Speaks a line of game text: strips its RPG Maker control codes (\PN, \V[n], \C[n]...) via clean, then
  # speaks. The common shape for voicing text that came from the game rather than a ready i18n string; readers
  # that already hold a clean line call speak directly. param interrupt true cuts current speech, false queues.
  def self.speak_clean(text, interrupt = true)
    speak(clean(text), interrupt)
  end

  # The last non-empty line spoken, for the spoken diagnostic ("last: ..."), or nil if nothing spoken yet.
  def self.last_spoken; @last_spoken; end
end

PokeAccess.write_marker("cargado ruby=#{RUBY_VERSION rescue '?'} sral=#{!PokeAccess::SRAL_SPEAK.nil?}\n")
