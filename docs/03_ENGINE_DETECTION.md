# Detección de Engine

## El Problema

Pokemon Essentials existe en múltiples versiones con APIs completamente diferentes:

| Versión | Era (por su API de datos) | Clases Batalla | Datos | Problemas |
|---------|-----|---|---|---|
| v16-v17 | gen-6 (2015) | `PokeBattle_Scene` | Constantes `PB*` | No existe `GameData` |
| v19-v21.1 | GameData (2019+) | `Battle::Scene` | `GameData::*` | Estructura completamente nueva |
| v22 | GameData + UI rework (2023+) | `Battle::Scene` | `GameData::*` | `UI::*` reemplaza windows |
| Sky Fork | v21 + v22 UI | Mixta | `GameData::*` | Backport de v22 UI a v21 |

> **Nomenclatura**: las dos grandes eras se nombran por **la API de datos** que usan (`gen6` = tablas
> `PB*`, `gamedata` = la capa `GameData`), no por "viejo/moderno": "moderno" envejece y un día mentiría,
> mientras que "usa GameData" es verdad permanente.

**Solución**: detección en tiempo de ejecución **por capacidad** (¿existe la clase/feature?), no por número
de versión, + selección de adaptadores.

## Módulo Engine

**Ubicación**: `core/foundation/engine.rb`

### Detección Básica

```ruby
module PokeAccess::Engine
  # ¿Existe GameData::Species? → usa la API GameData
  def self.gamedata?
    (defined?(GameData) && defined?(GameData::Species)) ? true : false
  end
  
  # Si NO usa GameData → es gen-6
  def self.gen6?
    !gamedata?
  end
  
  # Retorna :gamedata o :gen6
  def self.kind
    gamedata? ? :gamedata : :gen6
  end
end
```

**¿Por qué funciona?**
- `defined?()` en Ruby retorna nil si la constante no existe
- Gen-6 no tiene `GameData`, solo constantes globales
- La era GameData siempre tiene `GameData::Species` etc.

### Detección de Versión

```ruby
def self.version
  # Intenta leer Essentials::VERSION
  ev = (defined?(Essentials) && Essentials::VERSION rescue nil) ||
       (defined?(ESSENTIALS_VERSION) && ESSENTIALS_VERSION rescue nil)
  
  # Convierte "21.1" → 21.1 (Float)
  @version = if ev then ev.to_s[/\d+(\.\d+)?/].to_f
             elsif gamedata? then 19.0  # Sin constante? Asume v19+ si usa GameData
             elsif defined?(ESSENTIALSVERSION) then (v = ESSENTIALSVERSION.to_s[/\d+(\.\d+)?/].to_f; v < 1 ? 17.0 : v)
             else 16.0  # Último recurso: asume v16 gen-6
             end
end
```

**Ejemplos reales**:
```
Essentials::VERSION = "21.1"        → version = 21.1
ESSENTIALS_VERSION = "v22_1a"      → version = 22.0
defined?(Essentials) = nil          → Si usa GameData: 19.0, si gen6: 16.0
```

### Detección de Fork

```ruby
def self.fork
  return @fork if defined?(@fork)
  
  # Sky fork: usa GameData
  #          Y versión < 21.9
  #          Y tiene UI (v22 UI backported a v21)
  @fork = (gamedata? && version < 21.9 && defined?(UI) && defined?(UI::BaseScreen)) ? :sky : nil
end
```

## Métodos Clave de Selección

### 1. pick() - Elegir por engine

```ruby
def self.pick(map)
  # map = { :gamedata => valor_gamedata, :gen6 => valor_gen6, :default => fallback }
  map.fetch(kind) { map[:default] }
end

# Uso:
adapter = Engine.pick({
  :gamedata => "Battle::Scene",
  :gen6 => "PokeBattle_Scene"
})
```

### 2. for_engine() - Ejecutar condicional

```ruby
def self.for_engine(opts = {})
  yield if block_given? && matches?(opts)
end

# Uso:
Engine.for_engine(:only => :gamedata, :min => 21.0) do
  # Este código solo ejecuta si usa GameData y es v21+
  puts "Soporta GameData"
end

Engine.for_engine(:fork => :sky) do
  # Solo en Sky fork
  register_sky_plugins()
end
```

### 3. matches?() - Evaluador de especificaciones

```ruby
def self.matches?(opts = {})
  return false if opts[:min] && version < opts[:min]
  return false if opts[:max] && version > opts[:max]
  return false if opts[:fork] && fork != opts[:fork]
  
  case opts[:only]
  when :gen6     then return gen6?
  when :gamedata then return gamedata?
  when Numeric   then return version == opts[:only]
  end
  
  true
end

# Ejemplos:
Engine.matches?(:min => 19, :max => 21.1)  # ¿v19-v21.1?
Engine.matches?(:only => :gen6)              # ¿Gen-6?
Engine.matches?(:fork => :sky)               # ¿Sky fork?
```

### 5. has?() - Gate por capacidad (el canal único)

El gateo recomendado NO es por número de versión sino por **capacidad**: ¿existe la clase/método que el
lector necesita? Así un fork que backportea una feature (o una versión futura que la conserva) se activa
sin tocar el código. `Engine.has?` es el único punto para preguntarlo, y acepta tres formas:

```ruby
# 1) un símbolo de capacidad registrada (las transversales, en Engine::CAPABILITIES):
Engine.has?(:ui_rework)     # ¿existe el rework UI:: de v22?
Engine.has?(:gamedata)      # ¿usa la API GameData?
Engine.has?(:sky_fork)      # ¿es el fork de Sky?

# 2) un nombre de clase "A::B::C" (resuelto 1.8.7-safe vía PokeAccess.const_at):
Engine.has?("UI::BagVisuals")

# 3) "Clase#metodo" para exigir además un método (clave para forks que backportean):
Engine.has?("Battle::Scene#setIndexAndMode")
```

Si v23 renombra una clase, basta actualizar su entrada en `CAPABILITIES` (un sitio) y todos los lectores
que dependían de esa capacidad siguen funcionando. La carpeta `vNN/` solo dice DÓNDE se introdujo una
capacidad; la activación siempre es por `has?`.

### 4. player() - Obtener objeto jugador

```ruby
def self.player
  # Era GameData: $player
  # Gen-6: $Trainer
  (defined?($player) && $player) ? $player : (defined?($Trainer) ? $Trainer : nil)
end

# Uso universal (o via la fachada World.player, que delega aqui):
name = PokeAccess::Engine.player.name  # Funciona en ambas versiones
```

> Los lectores deberían leer los globales del juego (mapa, jugador, bolsa...) a través de la fachada
> `PokeAccess::World` (`core/foundation/world.rb`), no de `$player`/`$game_map` crudos: un único sitio que
> conoce el nombre por motor y que con `World.want(key, val)` deja una línea de log cuando un global
> esperado falta (un lector que enmudece se vuelve diagnosticable).

## Cómo se Usa en el Sistema

### Ejemplo 1: Battle System

```
core/
├── battle/
│   ├── battle.rb              ← Lógica compartida
│   ├── gen6/
│   │   └── battle_g6.rb       ← Hooks para PokeBattle_Scene
│   └── v21/
│       └── battle_v21.rb      ← Hooks para Battle::Scene

# En boot.rb:
load_manifest("core")  # Carga todo, inclusive battle_g6.rb y battle_v21.rb

# En battle_g6.rb:
# Solo existe PokeBattle_Scene en gen-6, así que estos hooks NO-OP en la era GameData
PokeAccess::Hooks.before_hook("PokeBattle_Scene", :pbDisplayMessage) do |scene, args|
  # This block only runs if PokeBattle_Scene exists (gen-6)
  PokeAccess.speak(args[0], false)
end

# En battle_v21.rb:
# Solo existe Battle::Scene en la era GameData, así que estos hooks NO-OP en gen-6
PokeAccess::Hooks.after_hook("Battle::Scene::MenuBase", :index=) do |menu, _r, _a|
  # This block only runs if Battle::Scene exists. Content is read by the agnostic module.
  PokeAccess::BattleScene.read_menu(menu)
end
```

**¿Cómo no entra en conflicto?**

Si ejecutas el juego y cargas ambos battle_g6.rb Y battle_v21.rb:
- En **gen-6**: `before_hook("PokeBattle_Scene", ...)` funciona, `before_hook("Battle::Scene", ...)` es NO-OP (clase no existe)
- En **era GameData**: `before_hook("Battle::Scene", ...)` funciona, `before_hook("PokeBattle_Scene", ...)` es NO-OP (clase no existe)

### Ejemplo 2: Data System

```ruby
# core/data/gen6/data_g6.rb -- es un MÓDULO; prioridad 10
module PokeAccess::DataG6
  def self.species_name(id); PBSpecies.getName(id) rescue nil; end
end
PokeAccess::Data.register(10, PokeAccess::DataG6) if defined?(PBMoves) && !defined?(GameData)

# core/data/v21/data_v21.rb -- MÓDULO; prioridad 20
module PokeAccess::DataV21
  def self.species_name(id); (GameData::Species.get(id).name rescue nil); end
end
PokeAccess::Data.register(20, PokeAccess::DataV21) if defined?(GameData)

# Uso (funciona en ambas versiones):
PokeAccess::Data.species_name(123)  # Automáticamente usa el provider activo
```

## Detección de Características Específicas

### Métodos que Varían por Versión

El objeto jugador ya lo resuelve `Engine.player` (ver arriba): devuelve `$player` o `$Trainer`
directamente, sin `eval`. No hay un `Engine.passable?` en el toolkit; la pasabilidad se consulta sobre
`$game_player.passable?` (que existe en ambos motores) desde el pathfinder.

El patrón normal NO es ramificar por versión, sino **gatear por existencia de clase/método**: cada hook
se registra solo donde la clase existe (ver [04_PATCHING_AND_HOOKS.md](04_PATCHING_AND_HOOKS.md)). Para
lo que sí difiere en la MISMA clase según versión, se usa `for_engine`:

```ruby
# Registra algo solo en v22+ (cuando hace falta distinguir dentro de una clase compartida):
PokeAccess::Engine.for_engine(:min => 22) do
  # ... comportamiento específico de v22 ...
end
```

## Diagnostic: Cómo Saber Qué Detectó

### Tecla de Diagnóstico: Ctrl+Alt+F9

```
# Genera/anexa accessibility/diag.txt. La sección de escena incluye, p.ej.:
...
scene=Battle::Scene              ← clase de la escena actual
in_menu=true
...
```
> Nota: el diag actual vuelca `scene=...` pero no líneas `engine.version/kind/fork`. Para ver la
> versión detectada desde código, usa `PokeAccess::Engine.version/kind/fork` (abajo).

### Tecla de Diagnóstico Hablado: Ctrl+Alt+F10

A diferencia de F9 (vuelca a archivo, que un usuario con lector de pantalla tendría que abrir), **F10
habla** el estado esencial al instante: escena activa, mapa y posición (en el campo), última línea hablada,
y el número de hooks que no engancharon. Es la respuesta rápida a "se quedó mudo, ¿por qué?".

### Lectura Manual en Código

```ruby
puts PokeAccess::Engine.version        # 21.1
puts PokeAccess::Engine.kind           # :gamedata
puts PokeAccess::Engine.gamedata?      # true
puts PokeAccess::Engine.fork           # nil
puts PokeAccess::Engine.has?(:ui_rework)  # false en v21 vanilla, true en v22/Sky
```

## Casos Especiales

### Sky Fork Detection

**¿Qué es Sky?**
- Fork de v21.1 que backportea la UI de v22
- Tiene tanto `GameData` (era GameData) como `UI` (v22)
- Algunas clases usan prefijo `UI::` en lugar de camelCase

**Detección**:
```ruby
@fork = (gamedata? && version < 21.9 && defined?(UI) && defined?(UI::BaseScreen)) ? :sky : nil
```

**Uso especial**:
```ruby
Engine.for_engine(:fork => :sky) do
  # Setup específico de Sky
  load_module("core/menus/skyflyer/eggmove.rb")
end
```

### Deluxe Battle Kit (DBK)

No se detecta automáticamente; es un plugin de Essentials que:
- Extiende `Battle::Scene` con más métodos
- Añade campos nuevos en el menú de batalla

**Manejo**:
```ruby
# Gatear por capacidad (clase + método), no por versión: así se activa también en un fork que lo backportee.
if PokeAccess::Engine.has?("Battle::Scene#pbToggleSpecialActions")
  # el hook DBK se registra (los archivos skyflyer/dbk_* ya hacen este gate)
end
```

## Árbol de Decisión

```
¿Existe GameData::Species?
├─ Sí → USA LA API GAMEDATA
│  ├─ ¿Versión < 21.9 Y existe UI::BaseScreen?
│  │  ├─ Sí → ES SKY FORK
│  │  └─ No → ES VANILLA (era GameData)
│  └─ ¿Versión?
│     ├─ 19-20 → v19-v20
│     ├─ 21-21.1 → v21
│     └─ 22+ → v22
└─ No → ES GEN-6
   └─ ¿Existe ESSENTIALS_VERSION?
      ├─ Sí → Parsear versión
      └─ No → Asumir v16
```

## Referencias

- [Engine Module](core/foundation/engine.rb)
- [Data Providers](core/data/) - Ejemplos de adaptadores
- [Battle Versions](core/battle/) - Diferentes hooks por versión
- [UI Adapters](core/menus/v21/, core/menus/v22/) - Menús adaptados

## Próximo

- [Patching & Hooks](04_PATCHING_AND_HOOKS.md) - Cómo se engancha el código
- [Data API](05_DATA_API.md) - Sistema de acceso a datos
