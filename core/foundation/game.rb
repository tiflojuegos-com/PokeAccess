module PokeAccess
  # Adapter API: the declarative surface a game profile uses to plug into the toolkit. Each method
  # forwards to a registration point, so it is a thin layer over the raw calls (which still work).
  module Game
    @profiles = []

    # The identifiers of the profiles defined so far (diagnostics only).
    def self.profiles; @profiles; end

    # Declares a game profile; the block registers its hooks/readers/puzzles/config. Additive and
    # repeatable (a game may use several define blocks).
    def self.define(name = nil, &blk)
      @profiles << name if name && !@profiles.include?(name)
      d = Definition.new(name)
      d.instance_eval(&blk) if blk
      d
    end

    # The receiver for a Game.define block; each method is a one-liner over the toolkit's API.
    class Definition
      def initialize(name = nil); @name = name; end

      # Overrides a Config setting.
      def config(key, value); PokeAccess::Config.send("#{key}=", value); end

      # Merges per-game button relabels into the remap menu (added to the defaults, never replacing).
      def button_labels(map); PokeAccess::Config.rebind_labels.merge!(map); end

      # Registers a focused-option reader for a command window. Yields (window, index) -> option text.
      def screen_reader(cname, &blk); PokeAccess::Menus.def_extractor(cname, &blk); end

      # Runs the block AFTER a method fires. Yields (instance, result, args).
      def after(cname, meth, &blk); PokeAccess::Hooks.after_hook(cname, meth, &blk); end

      # Runs the block BEFORE a method fires. Yields (instance, args).
      def before(cname, meth, &blk); PokeAccess::Hooks.before_hook(cname, meth, &blk); end

      # Wraps a method: the block runs around the original and must call the yielded nxt. Yields
      # (instance, nxt, args).
      def around(cname, meth, &body); PokeAccess::Hooks.around_hook(cname, meth, &body); end

      # Hooks a top-level function (a bare def, possibly on Kernel), for plugin functions that are not class
      # methods (e.g. pbItemBall). timing is :before/:after/:around; no-op where the function is absent.
      def kernel(fname, timing = :before, &body); PokeAccess::Hooks.wrap_kernel(fname, "game_#{@name}_#{fname}", timing, &body); end

      # Registers a remappable extra action (a raw key that would otherwise clash), reassignable from
      # the controls menu.
      def remap_extra(sym, default_vk, label); PokeAccess::Remap.register_extra(sym, default_vk, label); end

      # Runs a block once per frame in every scene, for menus the game drives from its own blocking loop.
      def poll_each_frame(&blk); PokeAccess::Keys.on_frame(&blk); end

      # Registers the block only on engines matching the spec, e.g. for_engine(:min => 22) { ... }
      # (see Engine.matches?). The common case is gated by class existence and needs no spec.
      def for_engine(opts = {}, &blk); PokeAccess::Engine.for_engine(opts, &blk); end

      # Registers a map puzzle (see Puzzles.register).
      def puzzle(map_id, opts); PokeAccess::Puzzles.register(map_id, opts); end

      # Registers an overworld hazard sprite pattern so matching events read with a label and a hazard cue.
      def hazard(pattern, label); PokeAccess::Locator.register_hazard(pattern, label); end

      # Maps picture file names to spoken text, for screens that light one picture per option.
      def picture_texts(map); PokeAccess::PictureCues::TEXTS.merge!(map); end

      # Registers a handler invoked when a picture is shown. Yields (picture_name, args).
      def on_picture(&blk); PokeAccess::PictureCues.register(&blk); end
    end
  end
end
