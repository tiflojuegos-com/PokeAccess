# Boot: the mod loader. Evaluates the toolkit in an explicit, dependency-ordered manifest -- core first,
# then the bundled game folder, then user settings on top. One shared mechanism for both loaders (mkxp-z
# preload and native RMXP injection). eval is intentional and safe: it loads our own trusted files shipped
# with the mod, in a fixed local folder, the same way RGSS runs every game script.
module PokeAccessBoot
  ROOT = "accessibility"

  # Loads core (by its manifest), then the bundled game (by its manifest), then applies user settings on
  # top so they override the per-game defaults.
  def self.run
    load_manifest("#{ROOT}/core")
    load_manifest("#{ROOT}/game")
    (PokeAccess::Settings.apply rescue nil) if defined?(PokeAccess) && PokeAccess.const_defined?(:Settings)
    miss = (PokeAccess::Hooks.missing rescue [])
    log("[diag] enganches sin metodo (posible typo): #{miss.join(', ')}") if miss && !miss.empty?
    if defined?(PokeAccess::Data) && (PokeAccess::Data.active_priority rescue nil).to_i <= 0
      log("[diag] PokeAccess::Data en modo emergencia: ningun provider de motor registrado (datos = id crudo)")
    end
    par = (PokeAccess::I18n.parity_issues rescue [])
    log("[diag] i18n sin paridad (clave en un idioma y no en otro): #{par.join(', ')}") if par && !par.empty?
  end

  # Reads <dir>/manifest.rb (an ordered array of "subsystem/name" entries) and evals each <dir>/<entry>.rb
  # in that order -- the manifest's order, never the filesystem's, so adding or moving a module is a
  # one-line edit and never depends on filename prefixes or glob ordering.
  def self.load_manifest(dir)
    mf = "#{dir}/manifest.rb"
    unless File.exist?(mf)
      log("#{dir}: sin manifest.rb")
      return
    end
    list = (eval(File.read(mf), TOPLEVEL_BINDING, mf) rescue nil)
    unless list.is_a?(Array)
      log("#{mf}: no devolvio una lista de modulos")
      return
    end
    list.each { |entry| load_module("#{dir}/#{entry}.rb") }
  end

  # Evaluates one module file, recording any error to the log instead of aborting the rest.
  def self.load_module(path)
    eval(File.read(path), TOPLEVEL_BINDING, path)
  rescue Exception => e
    raise if e.is_a?(SystemExit)
    log("#{path}: #{e.class}: #{e.message}\n#{(e.backtrace || []).join("\n")}")
  end

  # Appends a boot error to the log file. Uses the resolved data dir once Paths has loaded (it may pick a
  # writable AppData dir when the game folder is read-only), falling back to the default before then.
  def self.log(msg)
    dir = (defined?(PokeAccess::Paths) && PokeAccess::Paths.const_defined?(:DATA)) ? PokeAccess::Paths::DATA : "#{ROOT}/data"
    File.open("#{dir}/loader_error.txt", "a") { |fh| fh.write("#{msg}\n\n") }
  rescue StandardError
  end
end

PokeAccessBoot.run
