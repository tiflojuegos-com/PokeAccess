module PokeAccess
  # Opalo's custom trainer card (OpaloCard) that replaces the standard one. Two pages drawn in their own
  # loops with no cursor: pbStartScene shows name, money, Pokedex tally, play time and a star rank
  # ($game_variables[250]); badgeScene shows the earned badges and the Q-I keys that play each badge's
  # anthem. Read each page's content on entry (a before-hook on each method), since there is no per-move
  # redraw to hook.
  module OpaloCard
    STARS_VAR = 250

    # The data page: name, money, Pokedex, play time and star rank.
    def self.read_main
      return unless $Trainer
      parts = [PokeAccess::I18n.t(:tc_title), PokeAccess::I18n.t(:tc_name, :name => $Trainer.name)]
      mn = ($Trainer.money rescue nil)
      parts.push(PokeAccess::I18n.t(:tc_money, :n => mn)) if mn
      owned = ($Trainer.pokedexOwned rescue nil); seen = ($Trainer.pokedexSeen rescue nil)
      parts.push(PokeAccess::I18n.t(:tc_pokedex, :owned => owned, :seen => seen)) if owned && seen
      hm = PokeAccess::Util.playtime_parts((Graphics.frame_count / Graphics.frame_rate rescue nil))
      parts.push(PokeAccess::I18n.t(:tr_playtime, :h => hm[0], :m => hm[1])) if hm
      stars = ($game_variables[STARS_VAR] rescue nil)
      parts.push(PokeAccess::I18n.t(:tcard_stars, :n => stars.to_i)) if stars
      PokeAccess.speak(PokeAccess.clean(parts.join(", ")), true)
    rescue StandardError
      nil
    end

    # The badges page: how many badges are earned, plus the hint about the anthem keys.
    def self.read_badges
      return unless $Trainer
      n = PokeAccess::Util.badge_count($Trainer) || 0
      PokeAccess.speak(PokeAccess.clean(
        PokeAccess::I18n.t(:tr_badges, :n => n) + ". " + PokeAccess::I18n.t(:tcard_anthem_keys)), true)
    rescue StandardError
      nil
    end
  end
end

PokeAccess::Game.define("opalo") do
  before("OpaloCard", :pbStartScene) { |_s, _a| PokeAccess::OpaloCard.read_main }
  before("OpaloCard", :badgeScene) { |_s, _a| PokeAccess::OpaloCard.read_badges }
end
