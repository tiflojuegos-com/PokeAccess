module PokeAccess
  # Diagnostics constants.
  DLL_DIR   = PokeAccess::Paths::LIB
  MARK_FILE = "#{PokeAccess::Paths::DATA}/hook_loaded.txt"

  # Appends a diagnostic line to the load-marker file.
  def self.write_marker(extra = "")
    File.open(MARK_FILE, "a") { |f| f.write("#{Time.now}: #{extra}") }
  rescue StandardError
  end

  # Formats an error for a diagnostic line: an exception as "Class: message @ frame <- frame <- frame"
  # (its top three backtrace frames), or any other value as its string. Shared by log_once,
  # Audio3D.log3d, and Hooks.run_body so a swallowed failure reads the same everywhere.
  def self.format_error(e)
    return e.to_s unless e.respond_to?(:backtrace)
    "#{e.class}: #{e.message} @ #{((e.backtrace || [])[0, 3]).join(' <- ')}"
  end

  # Writes the FIRST failure for a given key to the marker, then stays silent for that key, so a per-frame
  # path that throws every frame leaves one diagnostic line instead of thousands. Accepts an exception or a
  # plain string. The single home for "log a swallowed error once" (Hooks.run_body and Audio3D.log3d follow
  # the same pattern over their own per-scope stores). Self-guarded so it can never itself raise out of a
  # rescue clause.
  def self.log_once(key, e)
    @logged_once ||= {}
    return if @logged_once[key]
    @logged_once[key] = true
    write_marker("#{key}: #{format_error(e)}\n")
  rescue StandardError
    nil
  end

  # Monotonic time in seconds, the source for all cue pacing: System.uptime on modern mkxp-z (which
  # advances by wall time even when the renderer runs above the nominal frame rate), else frame_count
  # over 40 on gen-6 (one game tick per frame), so cues stay paced to game time, not render rate.
  def self.clock
    t = (System.uptime rescue nil)
    return t.to_f if t
    fc = (Graphics.frame_count rescue nil)
    return 0.0 if fc.nil?
    fc.to_f / FPS
  end

  # Seconds between cues for a 0-100 frequency setting (higher = more frequent), paced in real game time:
  # ~0.15s at 100, ~1.5s at 0. Shared by the guide chime and the spatial pings so their cadence is identical.
  def self.freq_to_seconds(f)
    base = 6 + ((100 - f.to_i) * 54) / 100
    base = 4 if base < 4
    base / FPS
  end
end
