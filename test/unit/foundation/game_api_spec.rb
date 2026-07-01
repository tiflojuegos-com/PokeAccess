# Adapter API (#1): PokeAccess::Game.define forwards each declarative call to the SAME registration point
# the raw calls use, so a migrated profile behaves identically. Exercises every forwarder (config,
# button_labels, screen_reader, after) plus the per-frame registry (poll_each_frame -> Keys.on_frame, run by
# the single Input.update wrapper via run_frame_pollers).
Suite.define("game api: define forwards every declarative call") do
  hook_target = Class.new { def ping; :orig; end }
  Object.const_set(:ApiHookTarget, hook_target) unless Object.const_defined?(:ApiHookTarget)
  api_window = Class.new { def index; 2; end }
  Object.const_set(:ApiTestWindow, api_window) unless Object.const_defined?(:ApiTestWindow)

  api_log = []
  $api_log_ref = api_log
  old_money = PokeAccess::Config.money_label
  PokeAccess::Game.define("test_profile") do
    config(:money_label, :tr_money_generic)
    button_labels :q => "Quaff"
    screen_reader("ApiTestWindow") { |_w, i| "row#{i}" }
    after("ApiHookTarget", :ping) { |_i, r, _a| $api_log_ref << r }
  end
  truthy "profile registered", PokeAccess::Game.profiles.include?("test_profile")
  eq "config(key, val) applied", PokeAccess::Config.money_label, :tr_money_generic
  eq "button_labels merged", PokeAccess::Config.rebind_labels[:q], "Quaff"
  eq "screen_reader becomes an extractor", PokeAccess::Menus.focused_text(ApiTestWindow.new), "row2"
  ApiHookTarget.new.ping
  eq "after becomes a hook", api_log, [:orig]
  PokeAccess::Config.money_label = old_money

  $frame_log_ref = []
  PokeAccess::Game.define("frame_test") { poll_each_frame { $frame_log_ref << :tick } }
  PokeAccess::Keys.run_frame_pollers
  truthy "poll_each_frame registers and runs", $frame_log_ref.include?(:tick)
end
