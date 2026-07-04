# Arquitectura de PokeEssentialsAccess

## Visión General

PokeEssentialsAccess utiliza un modelo de **capas escalonadas** donde cada capa depende de las anteriores y ofrece servicios a las posteriores. Esta estructura permite:

1. **Reutilización**: El core se usa en todos los juegos
2. **Mantenibilidad**: Cambios en Essentials se adaptan en una sola capa
3. **Testabilidad**: Cada capa puede probarse independientemente
4. **Extensibilidad**: Nuevos juegos solo necesitan su capa específica

## Capas de la Arquitectura

### Capa 1: Foundation (Cimientos)

**Ubicación**: `core/foundation/`

**Propósito**: Subsistemas universales que todos los módulos necesitan

**Componentes**:

| Archivo | Responsabilidad |
|---------|-----------------|
| `config.rb` | Definición de todas las opciones de usuario |
| `const.rb` | Introspección 1.8.7-safe: resolución de constantes "A::B::C" (`const_at`/`const?`) e ivars/sprites de escenas (`ivar`/`ivar_i`/`sprite`) -- la primitiva que usan Hooks, Input y `Engine.has?` |
| `engine.rb` | Detección de engine por API de datos (`gamedata?`/`gen6?`) y gate por capacidad (`has?`) |
| `world.rb` | Fachada de globales del juego (mapa, jugador, bolsa...), engine-independiente; `want` loguea ausencias |
| `events.rb` | Bus de eventos interno (suscripción/emisión) |
| `caches.rb` | Registro de estado por-run; `reset_all` en `:map_changed` (cargar partida pasa por `Locator.forget_map` -> `:map_changed`) |
| `game.rb` | Sistema de definición de juegos específicos |
| `settings.rb` | Carga/guarda settings del usuario |
| `paths.rb` | Rutas de archivo (DATA, SOUNDS, etc.) |
| `i18n.rb` | Traducciones multiidioma; `parity_issues` valida es/en |
| `clipboard.rb` | Acceso al portapapeles (Win32API) |
| `perf.rb` | Monitoreo de rendimiento |
| `tags.rb` | Etiquetas de usuario para objetos |
| `map_names.rb` | Nombres legibles de mapas |

**Ejemplo de dependencia**:
```
const.rb  depende de: nada (introspección pura, 1.8.7-safe)
hooks.rb  depende de: const.rb (resolución de clase)
engine.rb depende de: const.rb (has? resuelve constantes)
world.rb  depende de: engine.rb (player delega en Engine.player)
caches.rb depende de: events.rb (se engancha a :map_changed)
settings.rb depende de: config.rb (lee el schema)
```

> **Regla de versiones**: una versión NUNCA depende de otra. El contenido agnóstico vive en la raíz del
> módulo (p.ej. `party/summary_gamedata.rb` = `SummaryGameData`, compartido por la escena clásica y v22);
> `party/gen6/summary_g6.rb` = `SummaryGen6` queda fuera del namespace agnóstico; las carpetas `vNN/` solo
> contienen DISPARADORES (qué clase enganchar), gateados por capacidad. Ver [03](03_ENGINE_DETECTION.md).

### Capa 2: Data (Acceso a Datos)

**Ubicación**: `core/data/`

**Propósito**: Abstracción de datos entre versiones de Essentials

**Por qué es necesario**:
- **Gen-6**: `PBSpecies.getName(123)` → "Scyther"
- **Era GameData**: `GameData::Species.get(123).name` → "Scyther"

**Solución**: Provider pattern

```ruby
module PokeAccess::Data
  @providers = []

  # Cada provider se registra SOLO si sus constantes existen en este juego (el guard vive en el
  # propio data_g6/data_v21), así que "el activo" es sencillamente el de mayor prioridad registrado.
  def self.register(priority, provider)
    @providers.push([priority, provider]); @active_entry = nil
  end

  def self.active_entry
    @active_entry ||= @providers.max_by { |pr| pr[0] }   # memoizado; se invalida al registrar
  end

  def self.active; e = active_entry; e && e[1]; end
end
```

**Archivos**:

| Archivo | Versión | Responsabilidad |
|---------|---------|-----------------|
| `data.rb` | Universal | Sistema de providers |
| `data_fallback.rb` | Fallback | Devuelve IDs crudos como último recurso |
| `gen6/data_g6.rb` | Gen-6 | Provider para v16-v17 (registra priority 10) |
| `v21/data_v21.rb` | v19+ | Provider para Essentials (era GameData) (registra priority 20) |

**Flujo**:
```ruby
# En cualquier módulo:
PokeAccess::Data.species_name(123)  # → llama al provider activo
  └─ Si v21 activo: GameData::Species.get(123).name
  └─ Si gen6 activo: PBSpecies.getName(123)
  └─ Si nada: "123" (fallback)
```

### Capa 3: Input & Speech (Entrada y Voz)

**Ubicación**: `core/input/`, `core/speech/`

**Propósito**: Interfaz con periféricos y síntesis de voz

**Componentes**:

| Módulo | Función |
|--------|---------|
| `speech/speech.rb` | SRAL.dll para síntesis de voz (Win32API) |
| `speech/text.rb` | Normalización/limpieza de texto hablado |
| `speech/markers.rb` | Logging de diagnóstico |
| `input/input.rb` | Polling de teclado (`Keys.global_poll`, `run_frame_pollers`) |
| `input/hooks.rb` | Semi-API de patching: `before_hook`/`after_hook`/`around_hook`/`frame_hook`/`wrap_global`/`wrap_kernel` con guarda de reentrancia (ver [04](04_PATCHING_AND_HOOKS.md)) |
| `input/remap.rb` | Remapeo de controles |

**Ejemplo: Síntesis de voz**:
```ruby
# core/speech/speech.rb
Win32API.new("SRAL.dll", "SRAL_Speak", ["p", "i"], "i")
  ├─ "p" = puntero a string (dirección de memoria)
  ├─ "i" = entero (0=encolar, 1=interrumpir)
  └─ Returns: "i" (integer status)

PokeAccess.speak("Entrada a Pelota Roja", true)  # Lee con síntesis
```

### Capa 4: Navigation & Audio 3D

**Ubicación**: `core/nav/`, `core/audio/`

**Propósito**: Sistemas de navegación y sonido posicional

**Sub-componentes Navigation**:

| Archivo | Responsabilidad |
|---------|-----------------|
| `locator.rb` | Encuentra eventos cercanos (NPCs, objetos) |
| `locator_naming.rb` | Genera nombres para eventos |
| `locator_surfaces.rb` | Identifica superficies (agua, árbol, etc.) |
| `pathfinder.rb` | Calcula rutas con A* y HPA* |
| `terrain.rb` | Clasifica terrenos (pasable, ledge, etc.) |
| `region_map.rb` | Navegación del mapa regional |

**Sub-componentes Audio 3D**:

| Archivo | Responsabilidad |
|---------|-----------------|
| `audio3d.rb` | Motor HRTF binaural (PA3D_steam.dll) |
| `spatial.rb` | Mapeo de eventos a emitores de sonido |

**Ejemplo: Audio 3D**
```ruby
# core/audio/audio3d.rb
PA3D_Init = Win32API.new("PA3D_steam.dll", "PA3D_Init", [], "i")
PA3D_Set = Win32API.new("PA3D_steam.dll", "PA3D_Set", 
  ["i", "i", "i", "i", "i"], "v")
  ├─ Argumentos: [channel, x, y, VOLUMEN(0-100), on(1/0)]  (NO hay eje Z: es panorámica 2D por HRTF)
  └─ Posiciona y reproduce/silencia un canal de audio
```

### Capa 5: Battle & Menus (Batalla y Menús)

**Ubicación**: `core/battle/`, `core/menus/`

**Propósito**: Accesibilidad de pantallas del juego

**Battle**:
```
core/battle/
├── battle.rb                 ← Lógica compartida
├── gen6/battle_g6.rb        ← Hooks para PokeBattle_Scene
├── v21/battle_v21.rb        ← Hooks para Battle::Scene
├── v22/battle_v22.rb        ← Hooks para v22 UI
└── skyflyer/                ← Deluxe Battle Kit específico
```

**Menus**:
```
core/menus/
├── menus.rb                 ← Framework universal (def_extractor, poll_sprite_menu)
├── neo_pausemenu.rb         ← Lector del menú de pausa "Neo" (un plugin concreto), no el genérico
├── command_help.rb          ← Línea de ayuda de pbShowCommandsWithHelp / pbShowCommandsRogue
├── battle_point_shop.rb     ← Lector opt-in de la tienda de PB (BattlePointShop.define)
├── sprite_button_menu.rb    ← Lector opt-in de menús de pausa de sprites (SpriteButtonMenu.define)
├── options.rb               ← Pantalla de opciones clásica (value_of: gen-6 optstart / v21 lowest_value; v22 va aparte en v22/options_v22.rb, opciones-hash)
├── pokedex_entry.rb         ← Entrada de Pokédex
├── v21/                     ← Lectores de las clases pre-rework (Battle::Scene, scenes/MUI)
└── v22/                     ← Lectores del rework UI:: (UI::*Visuals)
```

> Algunos plugins de la comunidad aparecen en muchos fangames pero no en todos: su lector vive en el core
> y un perfil **se suscribe** con una línea (`BattlePointShop.define(juego)`,
> `SpriteButtonMenu.define(juego)`, `LocationBanner.define(juego)`). Cada helper se describe por el
> PLUGIN/patrón que cubre, no por la lista de juegos que lo usan; si la clase del plugin no existe en ese
> juego, el hook no se ata (no-op).

> Nota de convención: el layout es **módulo-primero**. Cada subsistema (`battle/`,
> `menus/`, `party/`...) tiene sus lectores agnósticos en la raíz y subcarpetas `gen6/`, `v21/`, `v22/`,
> `skyflyer/` solo para lo que difiere por versión, cada una gateada por existencia de clase. La lógica
> COMPARTIDA por varias versiones va a la RAÍZ del módulo, no a una subcarpeta de versión: p.ej. el lector
> de los menús de combate vive en `core/battle/scene_reader.rb` (`PokeAccess::BattleScene`) porque las
> clases `Battle::Scene::*` son las mismas en v19-v22 vanilla; `battle_v21.rb` y `battle_v22.rb` solo
> enganchan los disparadores propios de su versión (cómo abre/navega cada una) y delegan el contenido en
> `BattleScene`. En gen-6 ese módulo se carga pero no se alcanza (sus disparadores no existen).

**Cómo funciona el hooking**:
```ruby
# Antes (código normal de Essentials):
class PokeBattle_Scene
  def pbDisplayMessage(msg)
    # Mostrar mensaje gráficamente
    @message_window.text = msg
  end
end

# PokeAccess hace (en gen6/battle_g6.rb):
PokeAccess::Hooks.before_hook("PokeBattle_Scene", :pbDisplayMessage) do |scene, args|
  PokeAccess.speak(args[0], false)  # Hablar ANTES de mostrar
  # El método original se ejecuta después automáticamente
end
```

### Capa 6: Field (Campo)

**Ubicación**: `core/field/`

**Responsabilidad**: Interacción con el mapa y eventos

**Componentes**:

| Archivo | Función |
|---------|---------|
| `contextual.rb` | Lectura de contexto del jugador |
| `minigames.rb` | Minijuegos estándar (p.ej. Voltorb Flip) |
| `minigame_text.rb` | Texto/navegación de minijuegos con ventana propia (p.ej. Triple Triad) |
| `fishing.rb` | Acceso a pesca |
| `berry.rb` | Sistema de bayas |
| `../puzzles/puzzles.rb` | Ayuda con puzles (subsistema propio `core/puzzles/`, no `field/`) |
| `achievements.rb` | Logros/medallas |
| `incubator.rb` | Incubadora de huevos |
| `location_banner.rb` | Lector opt-in de carteles de zona (LocationBanner.define) |
| `v21/` | Adaptadores específicos v21 |

### Capa 7: Juego Específico

**Ubicación**: `games/<nombre>/`

**Propósito**: Personalizaciones y constantes para cada juego

**Estructura**:
```ruby
# games/royal/manifest.rb
%w[
  constants       # Constantes específicas (botones, etc.)
  selectors       # Selectores del menú
  curry_select    # Sistema de curry específico
  hall_viewer     # Visualizador de salón específico
]
```

**Archivos típicos**:

| Archivo | Contenido |
|---------|----------|
| `manifest.rb` | Lista ordenada de módulos |
| `constants.rb` | `PokeAccess::Game.define("name")` - define juego |
| Otros módulos | Funcionalidad específica del juego |

### Juegos soportados

Cada juego soportado tiene su perfil en `games/<perfil>/` y un motor de Essentials. El perfil añade los
lectores de sus pantallas custom; el core cubre todo lo común a ese motor. (Al dar soporte a un juego
nuevo, añádelo a esta tabla y al CI.)

| Juego | Perfil | Motor |
|-------|--------|-------|
| Pokémon Z | `pokemon_z` | gen-6 (Ruby 1.8.7) |
| Pokémon Ópalo | `opalo` | gen-6 |
| Pokémon Reminiscencia | `reminiscencia` | gen-6 |
| Pokémon Realidea | `realidea` | gen-6 |
| Pokémon Armonía | `armonia` | gen-6 |
| Pokémon Africanvs | `africanus` | gen-6 |
| Pokémon Awakening | `awakening` | gen-6 |
| Pokémon Añil | `anil` | era GameData (Ruby 3.x, v21.1) |
| Pokémon Royal | `royal` | era GameData (fork de Sky / DBK) |
| Relict | `relict` | era GameData (fork de Sky / DBK) |
| (cualquier fangame gen-6 sin perfil) | `generic` | gen-6 (solo lectores del core) |

El motor decide la API que usan los lectores: gen-6 (`$Trainer`, `PokeBattle_Scene`, `PB*`) frente a
de la era GameData (`$player`, `Battle::Scene`, `GameData`); v22 añade el rework `UI::*`; el fork de Sky añade los
plugins del Deluxe Battle Kit. Ver [03_ENGINE_DETECTION.md](03_ENGINE_DETECTION.md).

## Flujo de Ejecución

### Inicio

```
1. MKXP-Z carga mkxp.json
2. Preload script (preload_access.rb) se ejecuta
3. Preload envuelve Graphics.update:
   
   Graphics.update originalmente    Graphics.update con preload
   └─ Actualiza pantalla           ├─ Comprueba si juego listo
                                    ├─ Si listo, eval boot.rb
                                    └─ Actualiza pantalla normalmente

4. boot.rb se ejecuta:
   PokeAccessBoot.run
   ├─ Carga core/ por manifest
   ├─ Carga game/<nombre>/ por manifest
   └─ Aplica settings de usuario
```

### Durante el Juego

```
Cada frame (el hook de Input#update):
├─ PokeAccess::Keys.global_poll → Detecta las hotkeys contextuales del jugador
├─ PokeAccess::Keys.run_frame_pollers → Corre los pollers registrados (poll_each_frame)
├─ El audio 3D y el localizador se actualizan en hooks de Game_Player (map_poll, etc.)
├─ Hooks personalizados disparan automáticamente:
│  ├─ Cuando un método de Essentials se llama
│  ├─ El hook lee contexto (batalla, menú, etc.)
│  └─ El hook actúa (hablar, actualizar audio, etc.)
└─ El juego original continúa normalmente
```

### Ejemplo Completo: Navegar a un NPC

```
Jugador presiona la hotkey de coordenadas/localizador (configurable, ver Config.keys)
  │
  ├─ PokeAccess::Keys.global_poll() la detecta (clase real: PokeAccess::Keys, no Input)
  │
  ├─ Dispara PokeAccess::Locator.rebuild_targets
  │  ├─ Escanea events cercanos
  │  ├─ Usa PokeAccess::Data para obtener nombres
  │  └─ Comprueba PokeAccess::Tags para etiquetas
  │
  ├─ Genera lista de destinos
  │
  ├─ Lee primer destino con PokeAccess.speak()
  │  └─ Llama SRAL.dll para síntesis de voz
  │
  └─ Configura ruta con PokeAccess::Pathfinder.find_path()
     ├─ Usa A* pathfinding
     ├─ Evita obstáculos
     └─ Devuelve lista de tiles [x, y]
```

## Modelo de Datos

### Config Schema

```ruby
PokeAccess::Config::SCHEMA = [
  [:language,            :es,   :lang,  :general, ...],
  [:auto_guide,          false, :flag,  :pathfinder, ...],
  [:audio3d_volume,      80,    :vol,   :audio, ...],
  # ...
]
```

- Cada fila = una opción de usuario
- Columnas: [key, default, kind, group, label_key, help_key]
- Validación automática por `kind` (flag, vol, sec, etc.)

### Tags de Usuario

```
# accessibility/data/tags.txt
123:456=Mi Arbol Magico	cat=objects
124:1=Puerta		hidden
125:10=Agua Azul		cat=water

Formato:
<map_id>:<event_id>=<nombre_personalizado>	[cat=<categoria>] [hidden]
```

## Patrones de Diseño Utilizados

### 1. **Provider Pattern** (Data)
Permite múltiples implementaciones sin condicionales

### 2. **Hook/Observer Pattern** (Hooks, Events)
Reacciona a cambios sin modificar clases

### 3. **Factory Pattern** (Game definition)
Crea configuraciones de juegos dinámicamente

### 4. **Singleton Pattern** (Módulos de PokeEssentialsAccess)
Acceso global thread-safe a subsistemas

### 5. **Module Mixin Pattern** (Extensiones)
Añade comportamiento sin herencia

### 6. **Capability Gating** (Engine.has?)
Los lectores se activan según una CAPACIDAD presente (clase/método existe), nunca por número de versión, así
que un fork o una versión futura que conserve la feature funciona sin cambios. La carpeta `vNN/` solo marca
dónde se introdujo. Canal único: `Engine.has?` (símbolo / "Clase" / "Clase#metodo").

### 7. **Cursor Dedup Primitive** (Cursor)
Una única primitiva (`core/menus/cursor.rb`) para "habla solo cuando el cursor cambia". Antes cada lector
abría su propio ivar `@access_*` y re-resolvía (y re-rompía) los casos límite; ahora todos van por
`Cursor.changed?/announce/reset`, con la lógica de dedup en un solo sitio.

### 8. **World Facade** (World)
Un único acceso a los globales del juego, engine-independiente (`$player` vs `$Trainer`...). Un global
ausente esperado se loguea una vez (`World.want`) en vez de tragarse, así un lector que enmudece deja rastro.

## Rendimiento

### Optimizaciones Clave

1. **Caché de rutas**: `route_cache` memoriza passable? entre updates
2. **Lazy loading**: Audio3D solo init si DLL disponible
3. **Flood memoización**: Reachability flood solo para targets lejanos
4. **Event batching**: Los hooks se agrupan, no se disparan cada frame
5. **Garbage collection**: Limpieza de caches cuando map cambia

### Profiling

```ruby
# Ctrl+Alt+F9 genera/anexa accessibility/data/diag.txt (Ctrl+Alt+F8 activa/desactiva el mod entero;
# Ctrl+Alt+F10 HABLA un diag corto: escena / mapa+pos / última lectura / hooks ausentes).
# diag.txt contiene timings en ms y una sección "runtime introspection" para diagnosticar
# pantallas mudas (clase del $scene, sus métodos e ivars). Ver docs/14_EXTENDING.md §6.
perf: map_poll=0.5ms audio3d=1.2ms pathfinder=2.1ms
```

## Siguientes Pasos

- [Engine Detection](03_ENGINE_DETECTION.md) - Cómo detecta versiones
- [Patching & Hooks](04_PATCHING_AND_HOOKS.md) - Sistema de hooks
- [Data API](05_DATA_API.md) - Cómo funciona acceso a datos
- [Extending](14_EXTENDING.md) - Cómo añadir hooks, lectores, puzzles y perfiles
