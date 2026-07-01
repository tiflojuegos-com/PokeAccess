module PokeAccess
  # Hook helpers. Several hooks may wrap the same method: each registers a middleware and they chain
  # (an onion) around the original, so a new feature can never silently disable an existing hook.
  module Hooks
    @chains = {}
    @missing = []
    @body_logged = []
    @reg_seq = 0

    # Bindings whose class exists but whose method does not -- almost always a typo'd method name (an
    # absent class is normal cross-game variance and is NOT recorded). Boot writes this to a marker.
    def self.missing; @missing; end

    # Registers a middleware around an instance method, chaining with any others already on it. The
    # saved-original alias is named per class and the guard checks methods defined ON the class only,
    # so hooking a parent then a child that overrides the same method does not bypass the child's logic.
    # Yields (instance, call_next, args); call call_next to run the rest of the chain.
    def self.wrap(cname, meth, &mw)
      k = PokeAccess.const_at(cname)
      return if k.nil?
      was_private = k.private_method_defined?(meth)
      unless k.method_defined?(meth) || was_private
        @missing << "#{cname}##{meth}" unless @missing.include?("#{cname}##{meth}")
        return
      end
      key = "#{cname}##{meth}"
      fresh = !@chains.has_key?(key)
      (@chains[key] ||= []).push(mw)
      return unless fresh
      orig = "#{meth}__pa_orig_#{cname.gsub(/[^a-zA-Z0-9]/, '_')}".to_sym
      own = (k.instance_methods(false) + k.private_instance_methods(false)).map { |m| m.to_sym }
      k.send(:alias_method, orig, meth) unless own.include?(orig)
      chains = @chains
      k.send(:define_method, meth) do |*args, &blk|
        call = lambda { send(orig, *args, &blk) }
        chains[key].reverse_each do |w|
          nxt = call
          call = lambda { w.call(self, nxt, args) }
        end
        call.call
      end
      k.send(:private, meth) if was_private
    rescue StandardError => e
      PokeAccess.write_marker("wrap #{cname}##{meth}: #{e.message}\n")
    end

    # Runs a hook body, swallowing exceptions so a throwing reader never breaks the game, but logging the
    # FIRST failure per cname#meth -- a method renamed inside a body (otherwise permanent, undiagnosable
    # silence on that game) becomes visible in the marker. Deduped, so a per-frame body that throws every
    # frame writes one line, not thousands.
    def self.run_body(key)
      yield
    rescue StandardError => e
      return if @body_logged.include?(key)
      @body_logged << key
      PokeAccess.write_marker("hook body #{key}: #{PokeAccess.format_error(e)}\n")
    end

    # A unique marker key per hook REGISTRATION (not per method), so when two hooks wrap the same cname#meth
    # (e.g. Game_Player#update from both audio3d and locator) a logged failure of one does not dedup-silence
    # a failure of the other.
    def self.next_key(cname, meth)
      @reg_seq += 1
      "#{cname}##{meth}@#{@reg_seq}"
    end

    # Runs body before the original (to speak before it blocks). Yields (instance, args).
    def self.before_hook(cname, meth, &body)
      key = next_key(cname, meth)
      wrap(cname, meth) { |inst, nxt, args| run_body(key) { body.call(inst, args) }; nxt.call }
    end

    # Runs body after the original, passing its result. Yields (instance, result, args).
    def self.after_hook(cname, meth, &body)
      key = next_key(cname, meth)
      wrap(cname, meth) { |inst, nxt, args| r = nxt.call; run_body(key) { body.call(inst, r, args) }; r }
    end

    # Wraps a method with full control of the call. Yields (instance, call_next, args); returns the result.
    # call_next replays the chain with the caller's ORIGINAL arguments (it takes none); to change what the
    # original receives, mutate the args array in place before calling call_next. The body keeps control of
    # call_next, so it is NOT swallowed; its first failure is logged then re-raised (preserving around's
    # semantics -- it may legitimately choose not to run the original).
    def self.around_hook(cname, meth, &body)
      key = next_key(cname, meth)
      wrap(cname, meth) do |inst, nxt, args|
        begin
          body.call(inst, nxt, args)
        rescue StandardError => e
          run_body(key) { raise e }
          raise e
        end
      end
    end

    # Wraps a top-level (Object instance) method -- a global Essentials function such as pbDisplayMail --
    # that the class hooks cannot reach. timing :before runs the block before the original (for blocking
    # calls whose announcement must precede them); :after runs it after and passes the result. The block
    # gets (args_array, return_value), nil for :before. No-op if undefined or already wrapped. 1.8.7-safe.
    def self.wrap_global(name, tag, timing = :after, &body)
      sym = name.to_sym
      ali = "#{name}__pa".to_sym
      return unless Object.private_method_defined?(sym) || Object.method_defined?(sym)
      return if Object.private_method_defined?(ali) || Object.method_defined?(ali)
      Object.send(:alias_method, ali, sym)
      before = (timing == :before)
      Object.send(:define_method, sym) do |*args, &blk|
        if before
          begin
            body.call(args, nil)
          rescue StandardError => e
            PokeAccess.log_once("global_#{name}", e)
          end
          send(ali, *args, &blk)
        else
          r = send(ali, *args, &blk)
          begin
            body.call(args, r)
          rescue StandardError => e
            PokeAccess.log_once("global_#{name}", e)
          end
          r
        end
      end
      Object.send(:private, sym, ali)
    rescue StandardError => e
      PokeAccess.write_marker("#{tag}: #{e.message}\n")
    end

    # Wraps a function that may be defined either as a Kernel singleton (def Kernel.foo, the gen-6 style) or
    # as a top-level Object method (def foo, the modern style) -- pbShowCommandsWithHelp is one such, varying
    # by game. Tries the Kernel singleton first, else falls back to wrap_global for the Object form.
    # timing :before / :after -> the block gets (args_array, return_value); :around -> the block gets
    # (args_array, call_next) and must call call_next (returns the original's result). No-op if undefined or
    # already wrapped. 1.8.7-safe.
    def self.wrap_kernel(name, tag, timing = :before, &body)
      sym = name.to_sym
      if Kernel.respond_to?(sym)
        ali = "#{name}__pa".to_sym
        sc = (class << Kernel; self; end)
        return if sc.method_defined?(ali) || sc.private_method_defined?(ali)
        sc.send(:alias_method, ali, sym)
        define_kernel_wrapper(sc, sym, ali, name, timing, body)
      else
        wrap_global_around(name, tag, timing, &body) if timing == :around
        wrap_global(name, tag, timing, &body) unless timing == :around
      end
    rescue StandardError => e
      PokeAccess.write_marker("#{tag}: #{e.message}\n")
    end

    # Installs the wrapper method on Kernel's singleton class for wrap_kernel, honouring the timing mode.
    def self.define_kernel_wrapper(sc, sym, ali, name, timing, body)
      sc.send(:define_method, sym) do |*args, &blk|
        case timing
        when :around
          body.call(args, lambda { send(ali, *args, &blk) })
        when :after
          r = send(ali, *args, &blk)
          begin; body.call(args, r); rescue StandardError => e; PokeAccess.log_once("kernel_#{name}", e); end
          r
        else
          begin; body.call(args, nil); rescue StandardError => e; PokeAccess.log_once("kernel_#{name}", e); end
          send(ali, *args, &blk)
        end
      end
    end

    # The Object-method form of an around wrap, for wrap_kernel's fallback when the function is top-level.
    def self.wrap_global_around(name, tag, _timing, &body)
      sym = name.to_sym
      ali = "#{name}__pa".to_sym
      return unless Object.private_method_defined?(sym) || Object.method_defined?(sym)
      return if Object.private_method_defined?(ali) || Object.method_defined?(ali)
      Object.send(:alias_method, ali, sym)
      Object.send(:define_method, sym) do |*args, &blk|
        body.call(args, lambda { send(ali, *args, &blk) })
      end
      Object.send(:private, sym, ali)
    rescue StandardError => e
      PokeAccess.write_marker("#{tag}: #{e.message}\n")
    end
  end
end
