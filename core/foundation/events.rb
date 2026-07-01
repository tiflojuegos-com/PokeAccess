module PokeAccess
  # In-process event bus for cross-feature reactions: a module emits a named event and subscribers run
  # (e.g. a tag edit triggers a locator rebuild).
  module Events
    @handlers = {}

    # Subscribes a block to an event; it runs (in subscription order) whenever the event is emitted.
    def self.on(name, &block)
      (@handlers[name] ||= []).push(block)
    end

    # Emits an event, running every subscriber with the given args (each guarded).
    def self.emit(name, *args)
      (@handlers[name] || []).each do |h|
        begin
          h.call(*args)
        rescue StandardError => e
          PokeAccess.log_once("event_#{name}", e)
        end
      end
    end
  end
end
