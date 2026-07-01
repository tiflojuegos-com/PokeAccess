# Árbol de Dependencias

Visualización completa de cómo los módulos dependen unos de otros.

## Diagrama General

```
MKXP-Z Engine (C++/Ruby Runtime)
    ↓
Graphics.update [hooked]
    ↓
AccessPreload (preload_access.rb)
    │ Espera: ¿$scene definido? o ¿120 frames?
    ↓
PokeAccessBoot.run (boot.rb)
    ├─ load_manifest("core")
    ├─ load_manifest("game")
    ├─ PokeAccess::Settings.apply
    └─ Diagnósticos
    ↓
PokeAccess Fully Loaded
```

## Jerarquía de Carga: CORE

```
core/manifest.rb (Orden de carga)
├── foundation/config
│   └─ SCHEMA = [[:language, :es, ...], ...]
│      KIND_BOUNDS = {:vol => [0, 100, ...], ...}
│
├── foundation/const
│   └─ PokeAccess.const_at("A::B::C") / const? - resolución de constantes 1.8.7-safe
│      ↑ CRITICO: lo usan Hooks, Input, Menus, Engine.has? (carga pronto, sin dependencias)
│
├── foundation/paths
│   └─ Resuelve DATA, SOUNDS, SAVES paths
│
├── foundation/i18n
│   └─ Carga lang/en.txt, lang/es.txt; I18n.parity_issues valida es/en
│
├── util/grouping
│   └─ Util.union_groups(n) { |i,j| ... } - agrupa por union-find (emisores/salidas cercanas)
│
├── util/text
│   └─ Util.join_parts(partes), Util.types_phrase(t1, t2) - ensamblado de líneas habladas
│
├── foundation/game
│   └─ Sistema para definir juegos específicos
│      PokeAccess::Game.define("royal") { ... }
│
├── foundation/engine
│   ├─ Detecta Engine.kind (:gamedata/:gen6)
│   ├─ Engine.version (16.0 / 19.0 / 21.1 / 22.0)
│   ├─ Engine.fork (:sky / nil)
│   ├─ Engine.has?(cap) - gate por capacidad (símbolo / "Clase" / "Clase#metodo"), vía const_at
│   └─ Métodos: gamedata?, gen6?, for_engine(), matches?()
│      ↑ CRITICO: usado por casi todo
│
├── foundation/world
│   └─ Fachada de globales: World.map / player_char / player / bag / on_map? / want (loguea ausencias)
│      depende de engine (player delega en Engine.player)
│
├── foundation/settings
│   └─ Carga/guarda config del usuario
│
├── foundation/events
│   └─ Bus de eventos (on/emit)
│
├── foundation/caches
│   └─ Caches.register(:x) { reset } / reset_all - se dispara en :map_changed (depende de events)
│
├── foundation/clipboard
│   └─ Acceso a portapapeles (Win32API)
│
├── foundation/perf
│   └─ Timers y profiling
│
├── foundation/tags
│   └─ Etiquetas de usuario para eventos
│      Depende de: Paths (lee tags.txt)
│
├── foundation/map_names
│   └─ Nombres de mapa personalizados (Locator.rename_map, Mayús+M); persiste en map_names.txt
│      Depende de: Paths
│
├── data/data
│   ├─ Definición del provider pattern
│   ├─ @providers = []
│   └─ active, register(), resolve()
│      ↑ BASE: usado por data_fallback, gen6, v21
│
├── data/data_fallback
│   └─ Provider fallback (priority 0)
│      Depende de: data/data
│
├── data/gen6/data_g6
│   ├─ module PokeAccess::DataG6
│   ├─ Accede a: PBSpecies, PBMoves, PBTypes, PBItems, etc.
│   ├─ Registra priority 10
│   └─ Solo se registra si existen las constantes (PBMoves && !GameData)
│      Depende de: data/data
│
├── data/v21/data_v21
│   ├─ module PokeAccess::DataV21
│   ├─ Accede a: GameData::Species, GameData::Move, etc.
│   ├─ Registra priority 20
│   └─ Solo se registra si existen las clases (GameData::Move)
│      Depende de: data/data
│
├── speech/markers
│   └─ write_marker(), log functions
│      Depende de: Paths (escribe a archivo)
│
├── speech/text
│   ├─ clean() - limpia etiquetas
│   └─ Depende de: nada
│
├── speech/speech
│   ├─ speak() - síntesis de voz
│   ├─ Accede a: SRAL.dll (Win32API)
│   └─ Depende de: markers
│
├── input/hooks
│   ├─ Definición del sistema de hooks
│   └─ before_hook(), after_hook(), missing()
│      Depende de: nada (Win32API puro)
│
├── input/remap
│   └─ Remapeo de controles
│      Depende de: Config (lee rebinds)
│
├── input/input
│   ├─ Polling de teclado
│   ├─ Accede a: GetAsyncKeyState (Win32API)
│   └─ Depende de: I18n, Config, markers
│
├── menus/config_menu
│   ├─ Menú de configuración genérico
│   └─ Depende de: Config, I18n, Data
│
├── nav/terrain
│   ├─ label(x, y) - tipo de terreno
│   ├─ ledge_at?(), surfable_at?(), ice?(), etc.
│   └─ Depende de: Essentials terrain tags
│
├── audio/spatial
│   └─ Mapeo de eventos a emitores de sonido
│      Depende de: Locator (obtiene eventos)
│
├── audio/audio3d
│   ├─ Audio3D engine (Steam Audio)
│   ├─ Accede a: PA3D_steam.dll (Win32API)
│   ├─ Canales: npc, object, door, teleporter, hazard, wall, interact, control, trap, push,
│   │            water, wind_*, step, grass, fstep_water, guide
│   └─ Depende de: Paths (busca .wav), Config (volúmenes)
│
├── field/contextual
│   ├─ Información contextual del jugador
│   └─ Depende de: Engine, Data, Terrain
│
├── field/minigame_text
│   ├─ Accesibilidad de minijuegos
│   └─ Depende de: Hooks
│
├── puzzles/puzzles            (subsistema propio, no field/)
│   ├─ Ayuda con puzles
│   └─ Depende de: Config (puzzle_assist)
│
├── field/achievements
│   ├─ Lectura de logros/medallas
│   └─ Depende de: Engine, Data
│
├── menus/cursor
│   └─ Cursor.changed?/on_change/announce/reset - primitiva única de dedup de cursor (carga antes de menus)
│
├── menus/menus
│   ├─ Framework de menús accesibles (def_extractor, poll_sprite_menu → delega en Cursor)
│   └─ Depende de: Hooks, Speech, I18n, Config, Cursor
│      (el hook genérico de Window_Selectable/Command vive en input/input, no aquí)
│
├── menus/neo_pausemenu
│   └─ Depende de: menus/menus, Hooks
│
├── battle/battle
│   ├─ Lógica compartida de batalla
│   ├─ Métodos: describe_battle(), describe_move(), etc.
│   └─ Depende de: Data, Engine, I18n, Speech, Info
│
├── battle/move_info
│   ├─ PokeAccess::MoveInfo: formato compartido del detalle de un movimiento (poder/precisión/PP/desc)
│   ├─ by_id(id) (agnóstico vía GameData), power_phrase / accuracy_phrase / line(...)
│   └─ Lo usan todos los lectores de movimientos (combate, relearner/egg-move, página de movs del summary)
│
├── battle/scene_reader
│   ├─ PokeAccess::BattleScene: lectura AGNÓSTICA de los menús Battle::Scene::* (comunes a v19-v22 vanilla)
│   ├─ read_menu / command_label / target_label / move_text / hp_change_text / ability_text
│   ├─ Solo DEFINE métodos (no engancha nada); lo invocan los hooks de v21/v22
│   └─ Depende de: Battle, MoveInfo, Data, I18n, Speech, Info
│
├── battle/gen6/battle_g6
│   ├─ Hooks específicos gen-6 (autónomo, no usa BattleScene)
│   ├─ Hookers: PokeBattle_Scene, CommandMenuDisplay, FightMenuDisplay
│   ├─ Cada hook se ata solo si la clase/método existe (gen-6)
│   └─ Depende de: Hooks, battle/battle
│
├── battle/v21/battle_v21
│   ├─ Solo los disparadores de v19-v21/Sky (index=, setIndexAndMode, mode=, shiftMode=, hp, mensajes)
│   ├─ El contenido hablado lo da battle/scene_reader (BattleScene)
│   ├─ Cada hook se ata solo si la clase/método existe
│   └─ Depende de: Hooks, battle/battle, battle/scene_reader
│
├── battle/v22/battle_v22
│   ├─ Solo los disparadores propios de v22 (set_index_and_commands, update_input, mega_evolution_state=)
│   ├─ El contenido hablado lo da battle/scene_reader (BattleScene)
│   ├─ Cada hook se ata solo si el método existe (v22)
│   └─ Depende de: Hooks, battle/battle, battle/scene_reader
│
├── battle/skyflyer/* (Sky fork / DBK)
│   ├─ dbk_battle, dbk_moveinfo, dbk_battlerinfo, dbk_selectors (Poké Ball + selección de combatiente)
│   ├─ Cursores de sprite del Deluxe Battle Kit; cada hook gateado por existencia de método
│   └─ Depende de: Hooks, battle/scene_reader
│
├── party/party_storage
│   └─ Depende de: Data, Engine, Hooks
│
├── menus/load
│   └─ Pantalla de cargar juego
│      Depende de: menus/menus, Hooks
│
├── field/berry
│   └─ Sistema de bayas
│      Depende de: Hooks, Data
│
└── nav/locator_naming
    ├─ Generación automática de nombres para eventos (target_name): etiqueta de usuario, Pokémon salvaje,
    │  peligro, movimiento de campo, PALANCA (toggle de 2 estados, dice "movida"/"sin mover"), salida,
    │  cartel, objeto. Detecta por la FORMA del dato del evento, no por nombre (agnóstico de juego).
    └─ Depende de: Tags, Data, I18n

(más módulos específicos...)
```

## Jerarquía de Carga: GAME

```
games/<nombre>/manifest.rb
├── constants
│   └─ PokeAccess::Game.define("royal") { ... }
│      └─ Establece constantes específicas del juego
│
├── Módulos específicos del juego
│   └─ Menús personalizados, selectors, etc.
│
└─ Depende de: core/ (completamente cargado)
```

## Árbol de Dependencias por Sistema

### Sistema de Datos (Data)

```
data/data
├─ Exporta: PokeAccess::Data module
├─ Métodos: register(), active(), resolve()
└─ Usado por: casi todo

data/data_fallback (priority 0)
├─ Proveedor de último recurso
└─ Siempre registrado

data/gen6/data_g6 (priority 10)
├─ Provider si gen-6
├─ Registra: PokeAccess::DataG6 (módulo)
└─ Accede a: PBSpecies, PBMoves, etc.

data/v21/data_v21 (priority 20)
├─ Provider si era GameData
├─ Registra: PokeAccess::DataV21 (módulo)
└─ Accede a: GameData::Species, etc.

Usuarios de Data:
├─ battle/battle
├─ speech/text (limpia tags)
├─ menus/menus (lee nombres de items, etc.)
├─ field/contextual
├─ party/summary
└─ muchos más...
```

### Sistema de Audio 3D

```
audio/spatial
├─ Escanea eventos cercanos
├─ Los convierte en emitores de sonido
└─ Depende de: Locator (targets)

audio/audio3d
├─ Motor HRTF Steam Audio
├─ Maneja canales de audio 3D
├─ Depende de:
│  ├─ Paths (busca .wav)
│  ├─ Config (volúmenes)
│  └─ native/PA3D_steam.dll
│
└─ Usuarios:
   └─ spatial.rb (emite pings)
```

### Sistema de Pathfinding

```
nav/pathfinder
├─ A* search
├─ HPA* clustering
├─ Flood reachability
└─ Depende de: Essentials passable?()

nav/locator_surfaces
├─ Encuentra superficies (agua, etc.)
├─ Depende de: Terrain.label()
└─ Retorna: SurfaceTarget structs

nav/locator_naming
├─ Genera nombres para eventos
├─ Depende de:
│  ├─ Tags (etiquetas personalizadas)
│  ├─ Data (obtiene categorías)
│  └─ I18n (traduce)
│
└─ Usuarios: Locator (necesita nombres)

nav/locator
├─ Centro de localización
├─ Combina: events, surfaces, exits
├─ Depende de: pathfinder, locator_naming, locator_surfaces
└─ Usuarios: Input (cuando presiona hotkey)
```

### Sistema de Battle

```
battle/battle (Compartido)
├─ Lógica universal de batalla
├─ Métodos como describe_move()
├─ Depende de: Data, I18n, Speech

battle/scene_reader (Agnóstico - BattleScene)
├─ Lectura de los menús Battle::Scene::* (comunes a v19-v22 vanilla y Sky)
├─ Solo define métodos; lo invocan los hooks de v21/v22
├─ Depende de: battle/battle, MoveInfo, Data, I18n, Speech

battle/gen6/battle_g6 (Gen-6)
├─ Hooks a PokeBattle_Scene / CommandMenuDisplay (autónomo, no usa BattleScene)
├─ Depende de: Hooks, battle/battle

battle/v21/battle_v21 (era GameData + Sky)
├─ Solo disparadores (index=, setIndexAndMode, mode=, shiftMode=, hp, mensajes) -> BattleScene
├─ Depende de: Hooks, battle/battle, battle/scene_reader

battle/v22/battle_v22 (v22)
├─ Solo disparadores propios de v22 (set_*, update_input, mega_evolution_state=) -> BattleScene
├─ Depende de: Hooks, battle/battle, battle/scene_reader

battle/skyflyer/* (Sky fork / DBK)
├─ dbk_battle, dbk_moveinfo, dbk_battlerinfo, dbk_selectors (ball + selección de combatiente)
├─ Depende de: Hooks, battle/scene_reader

Integración:
├─ Gen-6: Solo battle_g6 hace hooks
├─ v19-v21 y v22 vanilla: comparten las clases Battle::Scene::*; scene_reader lleva la lectura y
│  battle_v22 añade los binds de los métodos de apertura propios de v22
└─ Sky: battle_v21 + battle/skyflyer/*
```

### Sistema de Menús

```
menus/menus (Base)
├─ Framework universal (def_extractor, poll_sprite_menu)
├─ Depende de: Hooks, Speech, I18n
   (el hook genérico de ventanas de comando está en input/input, no aquí)

menus/neo_pausemenu
├─ Menú de pausa accesible
├─ Depende de: menus/menus, Hooks

menus/config_menu
├─ Menú de configuración de PokeAccess
├─ Depende de: Config schema, I18n, Speech

menus/v21/pausemenu_v21
├─ Adaptador para v21 (se ata si la clase/método existe)
├─ Depende de: menus/neo_pausemenu

menus/v22/pausemenu_v22
├─ Adaptador para v22 (se ata si la clase/método existe)
├─ Depende de: menus/neo_pausemenu
```

## Importancia Relativa

### CRÍTICO (Sin estos, nada funciona)

```
foundation/config      → Todas las opciones
foundation/engine      → Detección de versión
foundation/paths       → Rutas de archivo
data/data             → Abstracción de datos
speech/speech         → Síntesis de voz
input/hooks           → Sistema de extensión
```

### MUY IMPORTANTE

```
audio/audio3d        → Navegación por sonido
nav/pathfinder       → Búsqueda de rutas
menus/menus          → Accesibilidad de menús
battle/battle        → Accesibilidad de batalla
```

### IMPORTANTE

```
foundation/events    → Reactividad
foundation/i18n      → Multiidioma
input/input          → Polling de teclado
nav/locator          → Búsqueda de objetos
field/              → Interacción con campo
```

### OPCIONAL

```
field/achievements   → Lectura de logros
puzzles/puzzles      → Ayuda con puzles
field/fishing        → Acceso a pesca
```

## Dependencias Cruzadas

### Problemas Potenciales

❌ **Circular Dependency** (A depende de B, B depende de A):
```
NO EXISTE en PokeAccess
El manifest.rb está cuidadosamente ordenado para evitar esto
```

✅ **Forward References** (A usa B que carga después):
```
Permitido porque todo se carga ANTES de que el juego inicie
Ej: speech/speech puede referenciar a Paths porque Paths ya se cargó
```

### Regla de Oro

```
Si X depende de Y:
├─ Y DEBE estar en manifest ANTES de X
├─ O Y DEBE ser optional (check con defined?)
└─ O Y DEBE ser lazy-loaded (init on first use)
```

## Ejemplos de Validación

### ✅ Válido: forward reference

```ruby
# En menus/menus.rb (se carga después de speech/speech):
PokeAccess.speak("Menu abierto")  # OK, speech ya existe
```

### ❌ Inválido: backward reference

```ruby
# Si speech/speech.rb intentara:
PokeAccess::Menus.read_menu  # ERROR, menus no existe aún
```

### ✅ Válido: lazy check

```ruby
# En cualquier módulo:
if defined?(PokeAccess::Audio3D)
  PokeAccess::Audio3D.boot  # Solo si audio3d se cargó (idempotente)
end
```

## Validación del Orden

Para verificar que el orden es correcto:

```ruby
# En boot.rb después de cargar todo:
dependencies = {
  :config => [],
  :engine => [:config],
  :data => [:config],
  :gen6_data => [:data, :engine],
  :speech => [:paths],
  # ... completar
}

# Validar que cada módulo viene después de sus deps
```

## Extensión: Agregar Nuevo Módulo

Para agregar `core/mi_modulo/mi_modulo.rb`:

1. **Identificar dependencias**:
   ```ruby
   # ¿Qué necesita mi_modulo?
   - PokeAccess::Config         → Depende de config
   - PokeAccess::Engine         → Depende de engine
   - PokeAccess::Pathfinder     → Depende de nav/pathfinder
   ```

2. **Encontrar posición correcta en manifest**:
   ```ruby
   # core/manifest.rb
   ...
   foundation/engine           ← mi_modulo depende
   ...
   nav/pathfinder             ← mi_modulo depende
   ...
   mi_modulo/mi_modulo        ← INSERTAR AQUÍ
   ...
   menus/menus                ← módulos que usan mi_modulo
   ```

3. **Agregarlo**:
   ```ruby
   %w[
     # ... todo lo anterior ...
     my_module/my_module        # ← Nueva línea
     # ... todo lo posterior ...
   ]
   ```

## Diagnóstico de Problemas

Si un módulo no se carga:

```bash
$ cat accessibility/data/loader_error.txt

mi_modulo/mi_modulo: NoMethodError: undefined method 'speak' for PokeAccess:Module
  # Significa: mi_modulo intentó usar PokeAccess.speak
  # Pero speech/speech no se había cargado aún
  # SOLUCIÓN: Mover mi_modulo más abajo en manifest
```

---

Volver a [Índice](12_INDEX.md)
