# mkxp-z loader via preloadScript in mkxp.json. Preload scripts run before Scripts.rxdata, when the game
# classes do not exist yet, so loading is deferred: Graphics.update is wrapped and boot.rb is evaluated
# once the main loop is running (trigger: $scene being set, or a frame-count fallback for builds that
# never set it). Reversible: no Scripts.rxdata edit. eval is intentional and safe (boot.rb is our own
# trusted local file in a fixed folder).
module AccessPreload
  PATH        = "accessibility/boot.rb"
  ERROR_LOG   = "accessibility/data/loader_error.txt"
  START_MARK  = "accessibility/data/preload_started.txt"
  READY_FRAME = 120
  @loaded = false
  @frames = 0

  # Records that the preload script itself executed, independent of boot succeeding, so a missing boot
  # marker can be told apart from preloadScript not running at all.
  def self.mark_started
    File.open(START_MARK, "w") { |f| f.write("preload ok ruby=#{RUBY_VERSION rescue '?'}\n") }
  rescue StandardError
  end

  # Evaluates the toolkit once the main loop is running (scene set or frame fallback).
  def self.try_load
    return if @loaded
    @frames += 1
    return unless (defined?($scene) && $scene) || @frames >= READY_FRAME
    @loaded = true
    begin
      eval(File.read(PATH), TOPLEVEL_BINDING, PATH)
    rescue Exception => e
      raise if e.is_a?(SystemExit)
      (File.open(ERROR_LOG, "w") { |f|
        f.write("#{e.class}: #{e.message}\n#{(e.backtrace || []).join("\n")}")
      } rescue nil)
    end
  end

  class << Graphics
    unless method_defined?(:update__access_preload)
      alias_method :update__access_preload, :update
      def update(*a)
        r = update__access_preload(*a)
        AccessPreload.try_load
        r
      end
    end
  end
end

AccessPreload.mark_started
