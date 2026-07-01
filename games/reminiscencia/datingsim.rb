# Reminiscencia's dating-sim minigame. Most screens (task, build, support) use a Window_DrawableCommand
# subclass already read by the generic hook. The main hub is the exception: it shows its options as icon
# sprites and writes the focused label to a help window via setText (@commands[@index]). Read that label
# as the cursor moves. Guarded: a no-op where absent.
PokeAccess::Game.define("reminiscencia") do
  after("DatingSimMainScreen", :setText) do |scene, _r, _a|
    cmds = scene.instance_variable_get(:@commands)
    idx  = scene.instance_variable_get(:@index)
    txt  = (cmds.is_a?(Array) && idx) ? cmds[idx] : nil
    PokeAccess.speak(PokeAccess.clean(txt), true) if txt && !txt.to_s.empty?
  end

  # Task screen: the gender tabs (@indexGender 0 male / 1 female / 2 unknown) are a sprite cursor with no
  # window; setGenderPage runs when the tab changes, so announce the selected gender there. The command
  # window with the character names under each tab is read by the generic hook.
  gender_key = lambda do |g|
    { 0 => :rem_dating_male, 1 => :rem_dating_female, 2 => :rem_dating_unknown }[g]
  end
  after("DatingSimTaskScreen", :setGenderPage) do |scene, _r, _a|
    g = (scene.instance_variable_get(:@indexGender) rescue nil)
    k = gender_key.call(g)
    PokeAccess.speak(PokeAccess::I18n.t(k), true) if k
  end

  # Support screen: @index selects a character whose name and friendship points are drawn to side windows;
  # updatePoints runs on each up/down move, so read the focused character there (deduped by @index). The
  # partner command window is read by the generic hook.
  after("DatingSimSupportScreen", :updatePoints) do |scene, _r, _a|
    chars = (scene.instance_variable_get(:@characters) rescue nil)
    idx   = (scene.instance_variable_get(:@index) rescue nil)
    next unless chars.is_a?(Array) && idx && idx >= 0 && idx < chars.length
    next if idx == (scene.instance_variable_get(:@access_support) rescue nil)
    scene.instance_variable_set(:@access_support, idx)
    name = chars[idx][0]
    pts  = (datingGet(name, "fpPoints") rescue nil)
    txt  = pts ? PokeAccess::I18n.t(:rem_dating_points, :name => name, :n => pts) : name.to_s
    PokeAccess.speak(PokeAccess.clean(txt), true) if txt && !txt.to_s.empty?
  end
end
