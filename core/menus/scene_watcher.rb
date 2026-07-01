module PokeAccess
  # Wiring helper for screens that run their own blocking input loop, so the normal cursor hooks never fire
  # mid-loop and the focused item must be polled each frame instead. It holds the active scene for the
  # duration of the loop method (via an around-hook) and runs the reader's per-frame poll, removing the
  # identical around+poll_each_frame boilerplate that each such reader would otherwise repeat.
  module SceneWatcher
    # Wires a loop method to a reader module. cls/meth: the scene class and its blocking-loop method;
    # reader: a module responding to watch(scene), unwatch and poll. The hook self-gates on the class
    # existing, so it no-ops in games without that scene.
    def self.wire(cls, meth, reader)
      PokeAccess::Game.define do
        around(cls, meth) do |scene, call_next, _a|
          reader.watch(scene)
          begin
            call_next.call
          ensure
            reader.unwatch
          end
        end
        poll_each_frame { reader.poll }
      end
    end
  end
end
