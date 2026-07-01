# v22 town map (Essentials v22: UI::TownMapVisuals). The cursor is a 2D map point (not a linear index), and
# the screen redraws the location name on refresh_on_cursor_move, so that is hooked directly (not via the
# index-based on_nav). The focused location name comes from get_point_data[:real_name], resolved the same
# way refresh_map_name does, and deduped so holding a direction does not repeat.
if PokeAccess::V22.const_exists?("UI::TownMapVisuals")
  PokeAccess::Hooks.after_hook("UI::TownMapVisuals", :refresh_on_cursor_move) do |vis, _ret, _args|
    pd = (vis.send(:get_point_data) rescue nil)
    if pd && pd[:real_name]
      name = (pbGetMessageFromHash(MessageTypes::REGION_LOCATION_NAMES, pd[:real_name]) rescue pd[:real_name].to_s)
      name = name.gsub(/\\PN/, (PokeAccess::World.player.name rescue "")) rescue name
      PokeAccess::Cursor.announce(vis, :tm_name, (name.to_s.empty? ? nil : name)) { name }
    end
  end
end
