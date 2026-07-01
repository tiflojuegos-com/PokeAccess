# Cursor dedup primitive: almost every reader voices a focused entry the game re-asserts every frame, so it
# must speak only when the focus actually changes. announce speaks once per change; reset re-arms it so a
# reopened screen reads the same entry again; the key may be a tuple; and a nil holder falls back to the
# module-wide table. These are the subtle cases that were re-broken per file before Cursor centralised them.
Suite.define("cursor: announce speaks once per change, re-reads after reset") do
  holder = Object.new
  3.times { PokeAccess::Cursor.announce(holder, :slot, 5) { "entry five" } }
  spoke_once "an unchanged key speaks exactly once", /entry five/

  SpeakCapture.clear
  PokeAccess::Cursor.announce(holder, :slot, 6) { "entry six" }
  spoke "a changed key speaks again", /entry six/

  SpeakCapture.clear
  PokeAccess::Cursor.reset(holder, :slot)
  PokeAccess::Cursor.announce(holder, :slot, 6) { "entry six" }
  spoke "after reset the same key re-reads", /entry six/
end

# changed? gates arbitrary work: true only on a real change, false on the repeat and false on a nil key (a
# missing value must never speak).
Suite.define("cursor: changed? is true only on a real change") do
  holder = Object.new
  truthy "first key is a change", PokeAccess::Cursor.changed?(holder, :g, "a")
  falsy "same key is not a change", PokeAccess::Cursor.changed?(holder, :g, "a")
  truthy "a different key is a change", PokeAccess::Cursor.changed?(holder, :g, "b")
  falsy "a nil key never counts as a change", PokeAccess::Cursor.changed?(holder, :g, nil)
end

# A tuple key (e.g. [page, party_index]) is compared by value, and two readers on the same holder use
# distinct slots so they never shadow each other.
Suite.define("cursor: tuple keys and independent slots") do
  holder = Object.new
  truthy "first tuple is a change", PokeAccess::Cursor.changed?(holder, :a, [1, 2])
  falsy "the same tuple is not a change", PokeAccess::Cursor.changed?(holder, :a, [1, 2])
  truthy "a different tuple is a change", PokeAccess::Cursor.changed?(holder, :a, [1, 3])
  truthy "a second slot on the same holder is independent", PokeAccess::Cursor.changed?(holder, :b, [1, 3])
end

# A nil holder hangs the dedup state on the module-wide table keyed by slot (for readers with no instance),
# and reset on that table re-arms it.
Suite.define("cursor: nil holder uses the module-wide table") do
  truthy "first key on the global table is a change", PokeAccess::Cursor.changed?(nil, :global_slot, 1)
  falsy "the same global key is not a change", PokeAccess::Cursor.changed?(nil, :global_slot, 1)
  PokeAccess::Cursor.reset(nil, :global_slot)
  truthy "after reset the global key re-reads", PokeAccess::Cursor.changed?(nil, :global_slot, 1)
end
