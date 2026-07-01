module PokeAccess
  # Summary screen, shared helpers. The per-engine summary readers live alongside (gen-6 in
  # core/party/gen6/summary_g6.rb, modern in core/party/v21/summary_v21.rb); these methods are the parts both share,
  # so a game like Reminiscencia can reuse them without pulling in an engine-specific scene.
  module Summary
    @single_page = false

    # Lists a pokemon's moves with their pp. Engine-neutral: m.name on modern, PBMoves on gen-6.
    def self.moves_text(pk)
      return nil unless pk && pk.moves
      out = []
      pk.moves.each do |m|
        next unless m && m.id && m.id != 0
        t = (m.name rescue PokeAccess::Data.move_name(m.id))
        t += ". " + PokeAccess::I18n.t(:mv_pp, :pp => m.pp, :tot => m.totalpp) if m.respond_to?(:pp)
        out.push(t)
      end
      out.empty? ? PokeAccess::I18n.t(:sm_no_moves) : PokeAccess::I18n.t(:sm_moves, :list => out.join(", "))
    rescue StandardError
      nil
    end

    # Whether this game's summary is a single redrawn page (set true by a game like Reminiscencia),
    # suppressing the generic per-page reads.
    def self.single_page; @single_page; end

    # Marks the summary as single-page (called from a game file).
    def self.single_page=(v); @single_page = v; end
  end
end
