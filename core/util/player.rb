module PokeAccess
  module Util
    # Splits a play-time in seconds into [hours, minutes], the form every trainer-card / save-slot reader
    # speaks. Centralised because the two equivalent minute formulas ((s%3600)/60 vs (s/60)%60) were copied
    # inconsistently across readers. nil seconds -> nil. 1.8.7-safe.
    def self.playtime_parts(secs)
      return nil if secs.nil?
      s = secs.to_i
      [s / 3600, (s % 3600) / 60]
    end

    # The number of badges a player/trainer holds, tolerant of how the engine exposes it: numbadges or
    # badge_count when present, else counting the truthy entries of the badges array. nil when none resolves.
    def self.badge_count(who)
      n = (who.numbadges rescue nil)
      n = (who.badge_count rescue nil) if n.nil?
      if n.nil?
        b = (who.badges rescue nil)
        n = b.count { |x| x } if b.is_a?(Array)
      end
      n
    rescue StandardError
      nil
    end
  end
end
