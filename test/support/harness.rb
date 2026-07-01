# Loads the whole toolkit (core, then optionally a game profile) under the engine stubs, in the same
# manifest order boot.rb uses, so specs run against the real source. Collects any load error per file
# instead of aborting. The engine stubs are chosen by ENGINE (:gen6 default, :gamedata for the modern path).
#
# eval here is intentional and safe (same mechanism as the real loader boot.rb): it evaluates the toolkit's
# OWN trusted .rb files from the repo, in a fixed local folder, never external input. It is the only way to
# load the mod -- which expects the RGSS runtime -- under a plain desktop Ruby for testing.
ENGINE = (ENV["PA_ENGINE"] || "gen6").to_sym
require File.expand_path(ENGINE == :gamedata ? "stubs/engine_gamedata" : "stubs/engine_gen6", File.dirname(__FILE__))

module Harness
  ROOT = File.expand_path("../..", File.dirname(__FILE__))
  @errors = []

  # The load errors collected while loading the toolkit.
  def self.errors; @errors; end

  # Evaluates the modules listed in <rel>/manifest.rb, in that order -- the same manifest the real loader
  # uses, so the test exercises the real load order, not a glob.
  def self.load_dir(rel)
    dir = File.join(ROOT, rel)
    mf = File.join(dir, "manifest.rb")
    return unless File.file?(mf)
    list = (eval(File.read(mf), TOPLEVEL_BINDING, mf) rescue nil)
    unless list.is_a?(Array)
      @errors << "#{rel}/manifest.rb: did not evaluate to an Array of module paths (got #{list.class})"
      return
    end
    list.each do |entry|
      f = File.join(dir, "#{entry}.rb")
      begin
        eval(File.read(f), TOPLEVEL_BINDING, f)
      rescue Exception => e
        @errors << "#{rel}/#{entry}.rb: #{e.class}: #{e.message}"
      end
    end
  end

  # Loads core and, if given, a game profile, each via its manifest.
  def self.load_all(game = nil)
    load_dir("core")
    load_dir("games/#{game}") if game
    @errors
  end
end
