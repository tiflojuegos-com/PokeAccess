# Contextual info builders (the info key targets): summary_text, pokemon_info and move_info turn a Pokemon
# or move into a spoken line. A name-only Pokemon must NOT silence the line -- the stats and species still
# come through -- and a move with only an id must still read its name, type, power and accuracy via the data
# provider. Assertions match through I18n so they hold in whatever language is loaded.
Suite.define("info: summary_text keeps stats even on a bare Pokemon") do
  pk = Poke.build(:name => "Bulba", :species => 1, :level => 12,
                  :hp => 30, :totalhp => 44, :attack => 20, :defense => 18,
                  :spatk => 22, :spdef => 16, :speed => 25)
  text = PokeAccess::Info.summary_text(pk)
  truthy "summary is not silenced", text && !text.to_s.empty?
  match "reads the Pokemon name and level", text, /Bulba/
  match "includes the species line", text, /Especie1/
  match "includes the HP stat", text, /30/
  match "includes the Speed stat", text, /25/
end

# pokemon_info (the at-a-glance line): name, level and HP are always present; a held item and a status add a
# clause, while item 0 / status 0 add nothing.
Suite.define("info: pokemon_info reads name, level and HP at a glance") do
  pk = Poke.build(:name => "Char", :level => 30, :hp => 50, :totalhp => 70,
                  :item => 0, :status => 0, :gender => nil)
  glance = PokeAccess::Info.pokemon_info(pk)
  eq "matches the pk_glance template",
     glance, PokeAccess::I18n.t(:pk_glance, :name => "Char", :level => 30, :hp => 50, :tot => 70)
  truthy "nil Pokemon is nil", PokeAccess::Info.pokemon_info(nil).nil?
end

# move_info from an id-only move: a missing field never silences the line; the name is spoken at minimum, and
# type / power / accuracy are pulled from the data provider (gen-6: power via PBMoveData = 40 + id).
Suite.define("info: move_info fills fields from the data provider") do
  move = Object.new
  def move.id; 7; end
  text = PokeAccess::Info.move_info(move)
  truthy "move_info is not silenced", text && !text.to_s.empty?
  match "reads the move name", text, /Mov7/
  match "includes the power phrase", text, /#{PokeAccess::I18n.t(:mv_power, :p => 47)}/
  truthy "nil move is nil", PokeAccess::Info.move_info(nil).nil?
end
