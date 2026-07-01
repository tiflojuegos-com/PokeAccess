# Extender PokeEssentialsAccess: hooks, lectores, puzzles y perfiles

Esta guía es práctica: cómo **añadir accesibilidad a una pantalla nueva** sin tocar el core, usando
la DSL `PokeAccess::Game.define`. Todos los ejemplos son código real del repo. Si una pantalla custom
de un juego queda muda, este es el flujo para arreglarlo.

> Requisito previo: lee [04_PATCHING_AND_HOOKS.md](04_PATCHING_AND_HOOKS.md) (cómo funciona el motor de
> hooks por dentro) y [02_ARCHITECTURE.md](02_ARCHITECTURE.md) (capas y `games/<juego>/`).

---

## 0. El flujo completo, de pantalla muda a pantalla leída

1. **Diagnostica en runtime** (no abras el `Scripts.rxdata` del juego todavía). Entra en la pantalla
   muda y pulsa **Ctrl+Alt+F9**: vuelca `accessibility/diag.txt` con la sección
   `runtime introspection`, que te da la clase del `$scene`, sus métodos propios, sus ivars y las
   ventanas/sprites vivos. Ahí ves **qué método se llama al mover el cursor** y **qué ivar guarda el
   índice o los datos**.
2. **Elige el enganche**: un método que el juego llame en cada movimiento de cursor (o al abrir).
3. **Escribe el lector** en `games/<juego>/<algo>.rb` con `Game.define`.
4. **Añádelo al `manifest.rb`** del juego (orden de carga).
5. **Usa i18n** para todo texto hablado (`PokeAccess::I18n.t(:clave)` + claves en `lang/es.txt` y
   `lang/en.txt`). Nunca hardcodees strings nuevos.
6. **Pasa los tests** (`ruby test/run_all.rb` corre todo: specs de ambos motores, check187 y validaciones)
   e **instala** al juego.

---

## 1. La DSL `Game.define`

Toda la extensión específica de un juego pasa por un bloque `Game.define("perfil")`. Cada método del
bloque es una capa fina sobre la API del toolkit (definida en `core/foundation/game.rb`):

| Método | Para qué | Yield |
|--------|----------|-------|
| `after(clase, metodo)` | Correr código DESPUÉS de un método del juego | `(instancia, resultado, args)` |
| `before(clase, metodo)` | Correr código ANTES de un método | `(instancia, args)` |
| `around(clase, metodo)` | Envolver un método (debes llamar `nxt`) | `(instancia, nxt, args)` |
| `screen_reader(clase)` | Lector de la opción enfocada de una ventana de comandos | `(ventana, indice) -> texto` |
| `poll_each_frame` | Correr algo cada frame (para menús con loop propio) | — |
| `puzzle(map_id, opts)` | Registrar un puzzle de mapa | — |
| `picture_texts(map)` | Mapear nombres de imagen → texto hablado | — |
| `on_picture` | Handler al mostrar una imagen | `(nombre_imagen, args)` |
| `hazard(patron, label)` | Sprite de peligro con etiqueta + cue | — |
| `config(clave, valor)` | Sobrescribir una opción para ese juego | — |
| `button_labels(map)` | Renombrar botones en el menú de remap | — |
| `remap_extra(sym, vk, label)` | Acción extra remapeable | — |
| `for_engine(opts)` | Registrar solo en ciertas versiones de Essentials | — |

**Regla de oro:** cada hook se ata por **existencia de clase/método**. Si la clase no existe en ese
juego, el hook no se registra (no-op). Por eso un perfil puede declarar lectores para clases que solo
existen en una versión, sin romper las demás.

---

## 2. Añadir un lector a una pantalla custom (el caso más común)

### 2a. Menú basado en ventanas de comandos (`Window_DrawableCommand` y similares)

Si el diag muestra la pantalla en `live_cmd_windows`, el core probablemente ya la lee por su hook
genérico de `#update`. Si no la lee bien (etiqueta equivocada), usa `screen_reader`:

```ruby
# games/<juego>/mi_menu.rb
PokeAccess::Game.define("<juego>") do
  # Yields (ventana, indice) y devuelve el texto de la opción enfocada.
  screen_reader("Window_MiMenuCustom") do |win, idx|
    cmds = (win.instance_variable_get(:@commands) rescue nil)
    cmds && cmds[idx] ? PokeAccess.clean(cmds[idx].to_s) : nil
  end
end
```

### 2b. Lector de cursor de sprite (el patrón más repetido)

Es **el caso difícil y el más común** en pantallas custom: menús "bezier", quest logs, logros, los
selectores in-battle de DBK, el selector de bendiciones de Reminiscencia, las placas Arcy de Relict...
Ninguno tiene `Window_DrawableCommand`; son `Sprite`s con el resaltado movido por `src_rect`/un sprite
cursor, y el índice en un ivar privado. El core no los ve.

**La receta, siempre la misma (tres pasos):**

1. **Engancha el método de redibujado/selección** que el juego llama en cada movimiento de cursor (y al
   abrir). Lo descubres con el diag-runtime (sección 7): busca un `selectButton`/`updateCursor`/
   `refresh`/`showTexts`/`pbUpdate*` que corra al mover.
2. **Lee el ivar del índice** y **el ivar de los datos** (la lista de entradas).
3. **Deduplica por un ivar de la ESCENA** (`@access_*`) para no repetir la misma entrada cada frame, pero
   que sí vuelva a leer al reabrir.

```ruby
# Patrón: menú de pausa basado en sprites (algunos plugins reemplazan PokemonMenu_Scene por un panel
# bezier sin ventana de comandos). selectButton(index) corre en cada movimiento y en el selectButton(0)
# inicial; @buttons = [[key, label],...]
PokeAccess::Game.define("<juego>") do
  after("PokemonMenu_Scene", :selectButton) do |scene, _ret, args|
    idx = args[0]
    buttons = (scene.instance_variable_get(:@buttons) rescue nil)
    next unless buttons.is_a?(Array) && idx && idx >= 0 && idx < buttons.length
    label = (buttons[idx][1] rescue nil)
    PokeAccess.speak(PokeAccess.clean(label.to_s), true) if label && !label.to_s.empty?
  end
end
```

> Este patrón concreto (menú de pausa de sprites con `selectButton`/`@buttons`) está empaquetado en el
> core como `core/menus/sprite_button_menu.rb`: un perfil que tenga ese menú se suscribe con una línea,
> `PokeAccess::SpriteButtonMenu.define("<juego>")`, en vez de repetir el bloque. Escribe el `after(...)`
> a mano solo si tu pantalla se desvía del patrón.

Cuando el método NO recibe el índice como argumento (solo redibuja), dedupa con un ivar propio:

```ruby
# Ejemplo real: selector de bendiciones de Reminiscencia (games/reminiscencia/blessings.rb).
# updateCursor corre al abrir y en cada izq/der; @index = carta enfocada, @blessings = las 3 cartas.
after("PickBlessing", :updateCursor) do |scene, _r, _a|
  idx  = (scene.instance_variable_get(:@index) rescue nil)
  list = (scene.instance_variable_get(:@blessings) rescue nil)
  next unless list.is_a?(Array) && idx && idx >= 0 && idx < list.length
  next if idx == (scene.instance_variable_get(:@access_bless) rescue nil)   # dedup por instancia
  scene.instance_variable_set(:@access_bless, idx)
  PokeAccess.speak(texto_de_la_carta(list[idx]), true)
end
```

> **Otros ejemplos del repo con este mismo patrón**, por si quieres leer código real:
> `games/relict/plates.rb` (`rewriteArcyPlates`, índice por argumento),
> `core/battle/skyflyer/dbk_selectors.rb` (`pbUpdateBallSelection`/`pbUpdateBattlerSelection`, dedup por
> índice/par), y el helper `Menus.poll_sprite_menu` que comparten el Neo PauseMenu, el Ready Menu y el
> selector de tema del Pokégear.

Si el juego **no llama a ningún método** al mover (muta un ivar dentro de un loop propio), usa
`poll_each_frame` con dedup por el índice anterior — el patrón de `Menus.poll_sprite_menu`:

```ruby
PokeAccess::Game.define("<juego>") do
  poll_each_frame do
    sc = $scene
    next unless sc.is_a?(MiSceneSpriteBased)  # gate por clase
    idx = (sc.instance_variable_get(:@index) rescue nil)
    prev = (sc.instance_variable_get(:@access_idx) rescue nil)
    if idx && idx != prev
      sc.instance_variable_set(:@access_idx, idx)
      PokeAccess.speak(texto_de_la_opcion(sc, idx), true)
    end
  end
end
```

> **Dedup por ivar de la ESCENA, no a nivel de módulo.** Guardar el "último índice leído" en un ivar de
> la instancia (`@access_idx`) evita que la pantalla quede muda al reabrirse en el mismo estado. Esta es
> una convención dura del repo: un dedup a nivel de módulo deja la pantalla muda al reabrirla en el
> mismo estado, así que el "último índice leído" debe vivir en la instancia de la escena.

---

## 3. Añadir un puzzle

Los puzzles se registran por mapa con `puzzle(map_id, opts)`. Hay tres tipos (`:kind`):

- **`:grid`** — rejillas de runas en el suelo (no resolubles a ciegas). Anuncia cada celda con cue
  paneado por columna y pitch por fila.
- **`:state`** — mecanismos cuyo progreso vive en switches/variables invisibles (grúas, válvulas).
- **`:facing`** — estatuas rotables.

Ejemplo `:state` (mecanismo con un switch):

```ruby
PokeAccess::Game.define("<juego>") do
  puzzle(123, {
    :kind  => :state,
    :watch => [{ :switch => 45, :label => :puzzle_crank, :on => :puzzle_up, :off => :puzzle_down }],
    :solved     => lambda { $game_switches[50] },
    :solved_msg => :puzzle_done,
    :hint       => :puzzle_hint_crank   # solo se dice con puzzle_assist activado
  })
end
```

Las claves `:label/:on/:off/:solved_msg/:hint` son **símbolos i18n** (o strings literales). Los detalles
de cada tipo y sus `opts` están documentados en la cabecera de `core/puzzles/puzzles.rb:30-35`.

---

## 4. Crear un perfil de juego nuevo

Estructura mínima en `games/<juego>/`:

```
games/<juego>/
├── manifest.rb     # lista ordenada de los .rb del perfil (sin .rb, sin prefijos)
├── constants.rb    # Game.define con config/button_labels/constantes
└── <lectores>.rb   # un archivo por pantalla/sistema custom
```

`manifest.rb` (formato `%w[]`, orden = orden de carga):

```ruby
%w[
  constants
  pausemenu
  quests
  logros
]
```

`constants.rb` declara el perfil y su configuración base:

```ruby
PokeAccess::Game.define("<juego>") do
  config(:some_option, true)
  button_labels({ :aux1 => "Correr" })
end
```

**Convención de nombres de módulo:** un lector específico de un juego que pudiera colisionar con un
módulo del core debe llevar el prefijo del juego (p.ej. `ZBattleBag`, `ZCrafting`, `AnilMenus`,
`ZPokedex`), no un nombre genérico bajo `PokeAccess::`. Esto se blindó a propósito para evitar reabrir
módulos del core por accidente.

**Engine del juego:** determina si es gen-6 (Ruby 1.8.7: `$Trainer`, `PokeBattle_Scene`, `PBSpecies`) o
de la era GameData (`$player`, `Battle::Scene`, `GameData`). Si es gen-6, **todo el código del perfil debe pasar
`check187.py`** (sin `&.`, sin `->`, sin `Array#first(n)`, etc. — ver [08_RUBY_FUNDAMENTALS.md](08_RUBY_FUNDAMENTALS.md)).
Añade el perfil a la lista de perfiles que carga el CI (`.github/workflows/ci.yml`).

---

## 5. Lectores de plugins del fork de Sky (skyflyer / DBK)

El fork "La Base de Sky" (Relict, Royal) trae plugins que no existen en Essentials vanilla, sobre todo el
**Deluxe Battle Kit (DBK)**. Sus lectores viven en `core/battle/skyflyer/` (compartidos por todos los
juegos del fork), no en un perfil de juego, porque el plugin es el mismo en todos.

La regla aquí es **gatear por existencia de MÉTODO** (no solo de clase): DBK reabre `Battle::Scene` y le
añade métodos (`pbUpdateBallSelection`, `pbUpdateBattlerInfo`, `pbToggleSpecialActions`...). La clase
`Battle::Scene` existe en cualquier juego de la era GameData, así que comprobar la clase no basta; hay que comprobar
el método, para que el hook solo se ate en juegos con DBK y no genere un falso "missing" en los demás:

```ruby
# core/battle/skyflyer/dbk_selectors.rb (resumido)
# Gate por CAPACIDAD (clase + método), no por versión: se activa en vanilla v22, en Sky que lo backportee
# o en una versión futura que lo conserve. Engine.has? resuelve la clase 1.8.7-safe por debajo.
if PokeAccess::Engine.has?("Battle::Scene#pbUpdateBallSelection")
  PokeAccess::Hooks.after_hook("Battle::Scene", :pbUpdateBallSelection) do |scene, _ret, args|
    items = args[0]; index = args[1]
    # ... dedup vía Cursor.announce(scene, :ball_idx, index), leer items[index] (id de objeto + cantidad)
  end
end
```

Los selectores in-battle de DBK (qué Poké Ball lanzar, qué combatiente inspeccionar, las placas Arcy del
fork) son **cursores de sprite en la ruta crítica** (capturar, mecánica de tipos): exactamente el patrón
de la sección 2b, pero como van en `core/battle/skyflyer/` los comparte todo el fork. Lo específico de UN
juego del fork (p.ej. las placas Arcy, que solo están en Relict) sí va a su perfil
(`games/relict/plates.rb`).

> **No cruces versiones.** Un lector nunca debe llamar a otro de una versión distinta (eso significa que
> la lógica es agnóstica y debe subir a la raíz del módulo). La lectura compartida de los menús de combate
> vive en `core/battle/scene_reader.rb` (`PokeAccess::BattleScene`) justamente por esto: las clases
> `Battle::Scene::*` son las mismas en v19-v22 vanilla, así que `battle/v21` y `battle/v22` solo aportan
> sus disparadores y ambos llaman a `BattleScene`. Ver [02_ARCHITECTURE.md](02_ARCHITECTURE.md).

---

## 6. Reglas que evitan los errores recurrentes

- **i18n siempre.** Texto hablado nuevo = clave en `lang/es.txt` Y `lang/en.txt` (paridad exacta de
  claves). Excepción documentada: strings de juegos gen-6 que solo existen en español pueden quedarse,
  pero préfierase la clave i18n.
- **Todo bajo `rescue`.** Un lector que peta no debe tumbar el frame. El patrón del repo es
  `(expr rescue valor_por_defecto)`; el silencio en los `rescue` del mod es deliberado.
- **Dedup por instancia**, no por módulo (sección 2b).
- **Gate por clase/método.** Nunca asumas que una clase existe; el `Game.define`/`Hooks` ya lo hace por
  ti si usas `after`/`screen_reader` con el nombre como string.
- **Verifica e instala.** `ruby test/run_all.rb` (specs de ambos motores + check187 + validaciones), luego
  sincroniza el install del juego (la causa nº1 de "no lee" es un install desfasado, no el código).

---

## 7. Diagnosticar una pantalla muda (Ctrl+Alt+F8 / Ctrl+Alt+F9)

Cuando un colaborador (o un usuario) reporta "esta pantalla no lee nada", este es el flujo, sin abrir el
`Scripts.rxdata` del juego:

1. **Ctrl+Alt+F8** activa/desactiva el mod entero (para confirmar rápido que el mod está cargado y que el
   problema es esa pantalla, no el arranque).
2. Entra en la pantalla muda y pulsa **Ctrl+Alt+F9**: anexa a `accessibility/diag.txt` (con fecha) un
   bloque con dos partes — los timings de `perf` y la sección `runtime introspection` del `$scene` actual.

La sección `runtime introspection` te da todo lo necesario para escribir el hook:

- `$scene=<clase>` con `methods=[...]` — los **candidatos a enganchar** (busca un `update`/`refresh`/
  `pbUpdate`/`selectButton`/`showTexts` que corra en cada movimiento del cursor).
- `ivars: [@index=3, @buttons=Array(8), ...]` — **dónde está el índice y dónde los datos**.
- `@sprites keys=[...]` con la clase e índice de cada ventana — para menús basados en `@sprites`.
- `live_selectables=[...]` — ventanas `Window_Selectable`/`Window_Command` vivas y visibles, incluso si
  no son `Window_DrawableCommand` (si la pantalla aparece aquí, casi seguro el core ya la lee y el
  problema es otro: un install desfasado, ver sección 6).

**Lectura del diagnóstico (qué te dice cada caso):**

- ¿La pantalla **no** aparece como `live_selectables` ni como ventana de comando? → es un menú de sprite:
  engancha el método de selección y usa el patrón de la sección 2b.
- ¿Aparece pero **lee mal** (id crudo, etiqueta vacía)? → `screen_reader` (sección 2a).
- ¿`$scene` es una clase que **no esperabas** (nombre distinto al de otra versión)? → el juego renombró la
  clase; ata el hook al nombre real (el motor gatea por existencia, así que no rompe los demás).

Con eso escribes el hook sin extraer el fuente. Si aun así lo necesitas, los scripts compilados en
`Data/Scripts.rxdata` se vuelcan a texto con un cargador Marshal+Zlib (sin descompilar): se leen las
entradas `[magic, nombre, zlib]` y se infla cada una. El runtime introspection suele bastar para no llegar
a esto.
