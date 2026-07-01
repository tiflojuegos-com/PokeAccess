module PokeAccess
  # Locator part 2 of 4: terrain surfaces as navigation targets. Scans tiles around the player for
  # interesting surfaces and exposes the nearest of each as a synthetic SurfaceTarget, cached per tile.
  module Locator
    # Surface scan radius (tiles around the player searched for terrain targets).
    SURFACE_RADIUS = 30

    # A synthetic target standing for a map tile of a given surface, so navigation works on terrain like
    # on events. key is the language-neutral surface symbol (:surf_water...) for type matching.
    SurfaceTarget = Struct.new(:x, :y, :name, :key) do
      def character_name; ""; end
    end

    # kind => localization key for navigable surfaces (the per-tile resolution lives in Terrain.label).
    def self.surface_label_map
      PokeAccess::Terrain::LABEL
    end

    # Nearest tile of each interesting surface within SURFACE_RADIUS as synthetic targets, cached per tile.
    def self.surface_targets
      pos = [$game_player.x, $game_player.y, ($game_map.map_id rescue 0)]
      return @surface_cache if @surface_cache && @surface_cache_pos == pos
      best = {}
      px = $game_player.x; py = $game_player.y
      w = ($game_map.width rescue 0); h = ($game_map.height rescue 0)
      y0 = [0, py - SURFACE_RADIUS].max; y1 = [h - 1, py + SURFACE_RADIUS].min
      x0 = [0, px - SURFACE_RADIUS].max; x1 = [w - 1, px + SURFACE_RADIUS].min
      ty = y0
      while ty <= y1
        tx = x0
        while tx <= x1
          lbl = PokeAccess::Terrain.label(tx, ty)
          if lbl
            d = (tx - px).abs + (ty - py).abs
            best[lbl] = [d, tx, ty] if best[lbl].nil? || d < best[lbl][0]
          end
          tx += 1
        end
        ty += 1
      end
      @surface_cache_pos = pos
      @surface_cache = best.map { |lbl, info| SurfaceTarget.new(info[1], info[2], PokeAccess::I18n.t(lbl), lbl) }
    end

    # The connections involving a map, across engines: modern indexes getMapConnections by id and offers
    # eachConnectionForMap; gen-6 returns one flat list (reading it directly on modern would be wrong).
    def self.connections_for(id)
      if MapFactoryHelper.respond_to?(:eachConnectionForMap)
        list = []
        (MapFactoryHelper.eachConnectionForMap(id) { |c| list.push(c) } rescue nil)
        list
      else
        c = (MapFactoryHelper.getMapConnections rescue nil)
        c.is_a?(Array) ? c : []
      end
    rescue StandardError
      []
    end

    # The map id reached by stepping onto off-map (ox, oy) via a connection, or nil. Uses the engine's
    # own connection math, so it agrees exactly with where the game would transfer the player.
    def self.connection_dest(conns, id, ox, oy)
      conns.each do |conn|
        if conn[0] == id
          dims = (MapFactoryHelper.getMapDims(conn[3]) rescue [0, 0])
          nx = (conn[4] - conn[1]) + ox; ny = (conn[5] - conn[2]) + oy
          return conn[3] if dims[0] > 0 && nx >= 0 && nx < dims[0] && ny >= 0 && ny < dims[1]
        elsif conn[3] == id
          dims = (MapFactoryHelper.getMapDims(conn[0]) rescue [0, 0])
          nx = (conn[1] - conn[4]) + ox; ny = (conn[2] - conn[5]) + oy
          return conn[0] if dims[0] > 0 && nx >= 0 && nx < dims[0] && ny >= 0 && ny < dims[1]
        end
      end
      nil
    end

    # Synthetic exit targets for map-EDGE connections (walk off the edge into the next map): keeps the
    # nearest border tile per destination, labelled "salida a <map>". Without this, edge exits are
    # invisible to the locator (engines without MapFactoryHelper get none).
    # One exit target per connected destination. Cached per map_id (the cache self-invalidates when the
    # player changes map, since id then differs): the border scan below is O(perimeter x connections) and
    # otherwise ran on EVERY rebuild_targets (each event-end) -- the source of the occasional map_poll spike.
    def self.connection_targets
      return [] unless defined?(MapFactoryHelper) && $game_map && $game_player
      id = $game_map.map_id
      return @conn_targets if @conn_targets && @conn_targets_mid == id
      @conn_targets_mid = id
      @conn_targets = build_connection_targets(id)
    end

    # Builds the per-map exit targets, choosing one representative border tile per destination relative to
    # the map centre (the cache is per-map, not per-player-position, and any tile on a connected edge is a
    # valid exit for pathfinding).
    def self.build_connection_targets(id)
      conns = connections_for(id)
      return [] if conns.empty?
      w = ($game_map.width rescue 0); h = ($game_map.height rescue 0)
      return [] if w <= 0 || h <= 0
      cx = w / 2; cy = h / 2
      best = {}
      check = lambda do |tx, ty, ox, oy|
        dest = (connection_dest(conns, id, ox, oy) rescue nil)
        return unless dest
        d = (tx - cx).abs + (ty - cy).abs
        best[dest] = [d, tx, ty] if best[dest].nil? || d < best[dest][0]
      end
      (0...w).each { |x| check.call(x, 0, x, -1); check.call(x, h - 1, x, h) }
      (0...h).each { |y| check.call(0, y, -1, y); check.call(w - 1, y, w, y) }
      best.map do |dest, info|
        nm = (map_name(dest) rescue nil)
        label = nm ? PokeAccess::I18n.t(:loc_exit_to, :map => nm) : PokeAccess::I18n.t(:loc_exit)
        SurfaceTarget.new(info[1], info[2], label, nil)
      end
    rescue StandardError
      []
    end
  end
end
