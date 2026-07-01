module PokeAccess
  # v22 Pokemon storage / PC (Essentials v22: UI::PokemonStorageVisuals). index is -1 box name, -2 party
  # button, -3 close, 0+ a slot; box is -1 (party panel) or a box number; @storage is the PokemonStorage.
  # The cursor moves via set_index, read here as the focused box pokemon, party member, or control, reusing
  # the pc_* strings shared with the gen-6 PC reader. (Held-Pokemon swap prompts are a later refinement.)
  module StorageV22
    # The spoken line for the focused storage cursor position. Negative indices are the box chrome: -1 box
    # name, -2 party button (Back when in the party panel, box -1), -3 close; >= 0 is a slot.
    def self.line(vis)
      idx     = (vis.index rescue nil)
      box     = (vis.box rescue nil)
      storage = (vis.instance_variable_get(:@storage) rescue nil)
      return nil if idx.nil?
      in_box = box.is_a?(Integer) && box >= 0
      held = ((vis.holding_pokemon? ? vis.pokemon : nil) rescue nil)
      case idx
      when -1 then PokeAccess::I18n.t(:pc_box, :name => (storage[box].name rescue ""))
      when -2 then in_box ? PokeAccess::I18n.t(:pc_team) : PokeAccess::I18n.t(:pc_back)
      when -3 then PokeAccess::I18n.t(:pc_close)
      else
        cols = PokeAccess::Party::BOX_COLUMNS
        pk  = in_box ? (storage[box, idx] rescue nil) : (storage.party[idx] rescue nil)
        pos = in_box ? PokeAccess::I18n.t(:pc_pos, :row => idx / cols + 1, :col => idx % cols + 1) : ""
        if held
          pk ? PokeAccess::I18n.t(:pc_swap, :name => pk.name, :held => held.name) + pos :
               PokeAccess::I18n.t(:pc_place, :held => held.name) + pos
        elsif pk
          PokeAccess::Info.set_info(:pokemon, pk)
          t = PokeAccess::I18n.t(:pc_slot, :name => pk.name, :level => pk.level)
          t += PokeAccess::Party.fainted_suffix(pk)
          t + pos
        else
          PokeAccess::I18n.t(:pc_empty) + pos
        end
      end
    rescue StandardError
      nil
    end
  end
end

PokeAccess::V22.on_nav("UI::PokemonStorageVisuals", :set_index) { |vis| PokeAccess::StorageV22.line(vis) }
# Cycling boxes (LEFT/RIGHT on the box-name row) calls go_to_next_box/go_to_previous_box directly without
# touching @index, so set_index never fires; hook them too so the new box is announced (deduped by the box
# name, which changes even though the index stays -1).
PokeAccess::V22.on_nav("UI::PokemonStorageVisuals", :go_to_next_box) { |vis| PokeAccess::StorageV22.line(vis) }
PokeAccess::V22.on_nav("UI::PokemonStorageVisuals", :go_to_previous_box) { |vis| PokeAccess::StorageV22.line(vis) }
