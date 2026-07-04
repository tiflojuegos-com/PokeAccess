# Gen-6 Move Relearner (MoveRelearnerScene, no underscore -- the vanilla gen-6 class, distinct from the
# modern MoveRelearner_Scene read in menus/v21). Its move list is a Window_CommandPokemon whose bare names the
# generic reader already voices, but the focused move's full detail (type/power/accuracy/description) is only
# hand-drawn in pbDrawMoveList. Without this, gen-6 games spoke only the move name while the modern relearner
# and the forget-move screen spoke everything -- the inconsistency players reported. Mute the bare-name read
# and speak the full detail on each redraw, via MoveInfo.by_id_via_data (PBMoveData on gen-6). The BetterMove-
# Relearner plugin (e.g. Pokemon Z) stores @moves as [id, "MT"] pairs; vanilla stores plain ids, so unwrap.
module PokeAccess
  module MoveRelearnerGen6
    # The move id under the focused list row, unwrapping a [id, tag] pair (BetterMoveRelearner) to its id.
    def self.focused_id(scene)
      moves = PokeAccess.ivar(scene, :@moves)
      win = PokeAccess.sprite(scene, "commands")
      idx = (win.index rescue nil)
      return nil unless moves.is_a?(Array) && idx && idx >= 0 && idx < moves.length
      m = moves[idx]
      m.is_a?(Array) ? m[0] : m
    rescue StandardError
      nil
    end

    # Speaks the focused move's full detail (or nothing when it cannot be resolved).
    def self.detail(scene)
      id = focused_id(scene)
      return if id.nil?
      s = PokeAccess::MoveInfo.by_id_via_data(id)
      PokeAccess.speak(s, true) if s && !s.to_s.empty?
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Hooks.after_hook("MoveRelearnerScene", :pbStartScene) do |scene, _r, _a|
  w = PokeAccess.sprite(scene, "commands")
  w.instance_variable_set(:@ignore_input, true) if w
end
PokeAccess::Hooks.after_hook("MoveRelearnerScene", :pbDrawMoveList) do |scene, _r, _a|
  PokeAccess::MoveRelearnerGen6.detail(scene)
end
