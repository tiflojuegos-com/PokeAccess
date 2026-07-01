module PokeAccess
  # Formatter for a relearnable/summary move id used by the v22 summary moves page (summary_v22). It only
  # formats: the relearner cursor itself is voiced by the shared move-cursor reader, so adding a cursor hook
  # here would double-read. Kept as a thin named entry point so summary_v22 has a stable call site.
  module MoveReminderV22
    # The spoken detail for a relearnable move id, via the agnostic MoveInfo.by_id, with the id-string
    # fallback the v22 summary expects when the move cannot be resolved.
    def self.move_line(id)
      (PokeAccess::MoveInfo.by_id(id) rescue nil) || id.to_s
    end
  end
end
