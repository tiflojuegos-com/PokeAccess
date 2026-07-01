# Opalo new-game selector (event-driven pictures). The difficulty screen lights exactly one "...Dif#Claro"
# at a time, so those read directly via TEXTS. The first screen (Normal vs Nuzlocke) lights BOTH options at
# once, so there the pointer Y marks the selection (y~60 = Normal on top, y~210 = Nuzlocke below). ASCII
# only (ruby 1.8.7 / 3.1).
PokeAccess::Game.define("opalo") do
  picture_texts(
    "MenuNuzNormalDif1Claro" => "Maestro. Los Pokemon debilitados mueren permanentemente; si pierdes un combate pierdes el reto.",
    "MenuNuzNormalDif2Claro" => "Normal. Los Pokemon debilitados mueren permanentemente; tienes 1 resurreccion por gimnasio y 2 oportunidades mas si pierdes un combate.",
    "MenuNuzNormalDif3Claro" => "Asistido. Los Pokemon debilitados mueren permanentemente; tienes 3 resurrecciones por gimnasio y 5 oportunidades mas si pierdes un combate."
  )
end

module PokeAccess
  module OpaloModes
    NORMAL = "Modo Normal. Juega a Pokemon de forma tradicional, sin reglas adicionales."
    NUZ    = "Modo Nuzlocke. Los Pokemon debilitados pueden morir permanentemente. Hay varios modos de dificultad."
    @screen = nil
    @last = nil

    # Tracks which selector screen is active and, on the first screen, reads the option the pointer is on
    # (the difficulty screen reads itself via TEXTS). param y the picture y position
    def self.handle(name, y)
      if name =~ /MenuNuzNormalClaro$/ || name =~ /MenuNuzNuzClaro$/
        @screen = :first
      elsif name =~ /MenuNuzNormalDif/
        @screen = :diff
      elsif name =~ /MenuNuzPuntero/ && @screen == :first
        sel = y.to_i < 120 ? NORMAL : NUZ
        return if sel == @last
        @last = sel
        PokeAccess.speak(sel, true)
      end
    end
  end
end

PokeAccess::Game.define("opalo") do
  on_picture { |name, args| PokeAccess::OpaloModes.handle(name, args[3]) }
end
