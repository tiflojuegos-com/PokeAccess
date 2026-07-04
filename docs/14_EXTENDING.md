# Extender PokeEssentialsAccess: hooks, lectores, puzzles y perfiles

Esta guía es práctica: cómo **añadir accesibilidad a una pantalla nueva** sin tocar el core, usando
la DSL `PokeAccess::Game.define`. Todos los ejemplos son código real del repo. Si una pantalla custom
de un juego queda muda, este es el flujo para arreglarlo.

> Requisito previo: lee [04_PATCHING_AND_HOOKS.md](04_PATCHING_AND_HOOKS.md) (cómo funciona el motor de
> hooks por dentro) y [02_ARCHITECTURE.md](02_ARCHITECTURE.md) (capas y `games/<juego>/`).

---

## 0. El flujo completo, de pantalla muda a pantalla leída

1. **Diagnostica en runtime** (no abras el `Scripts.rxdata` del juego todavía). Entra en la pantalla
   muda y pulsa **Ctrl+Alt+F9**: vuelca `accessibility/data/diag.txt` con la sección
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
| `kernel(fname, timing)` | Hookear una función top-level (bare `def`, posible en `Kernel`), p.ej. `pbItemBall` | `(args, retorno)` (`:around` → `(args, nxt)`) |
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
   abrir). Lo descubres con el diag-runtime (sección 8): busca un `selectButton`/`updateCursor`/
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
    buttons = PokeAccess.ivar(scene, :@buttons)   # lectura de ivar segura (foundation/const.rb)
    next unless buttons.is_a?(Array) && idx && idx >= 0 && idx < buttons.length
    label = (buttons[idx][1] rescue nil)
    PokeAccess.speak_clean(label.to_s, true) if label && !label.to_s.empty?
  end
end
```

> **`speak_clean` vs `speak`.** `PokeAccess.speak_clean(text, interrupt)` limpia los códigos de control de
> RPG Maker (`\PN`, `\V[n]`, `\C[n]`...) y habla; es la forma correcta para texto que viene del juego. Si ya
> tienes una línea limpia (una clave i18n ya resuelta), usa `PokeAccess.speak(text, interrupt)` directo.
> `PokeAccess.ivar(obj, :@x, fallback)` lee un ivar sin que un objeto raro tumbe el frame.

> Este patrón concreto (menú de pausa de sprites con `selectButton`/`@buttons`) está empaquetado en el
> core como `core/menus/sprite_button_menu.rb`: un perfil que tenga ese menú se suscribe con una línea,
> `PokeAccess::SpriteButtonMenu.define("<juego>")`, en vez de repetir el bloque. Escribe el `after(...)`
> a mano solo si tu pantalla se desvía del patrón.

Cuando el método NO recibe el índice como argumento (solo redibuja), deduplica con el primitivo `Cursor`
(`core/menus/cursor.rb`) en vez de un ivar `@access_*` a mano. `Cursor.announce(holder, slot, key) { linea }`
habla solo cuando `key` cambia respecto a lo último que `slot` guardó EN `holder`, limpia la línea y por
defecto interrumpe. El estado de dedup vive en la instancia (`holder`), así que muere con la escena y al
reabrir vuelve a leer:

```ruby
# Ejemplo: selector de tipo "elige entre N cartas". updateCursor corre al abrir y en cada izq/der;
# @index = carta enfocada, @blessings = las cartas. slot (:bless) es un símbolo propio de este lector.
after("PickBlessing", :updateCursor) do |scene, _r, _a|
  idx  = PokeAccess.ivar(scene, :@index)
  list = PokeAccess.ivar(scene, :@blessings)
  next unless list.is_a?(Array) && idx && idx >= 0 && idx < list.length
  PokeAccess::Cursor.announce(scene, :bless, idx) { texto_de_la_carta(list[idx]) }
end
```

> **`first_interrupt` — encolar la primera lectura.** Cuando una pantalla se abre encima de una pregunta o
> título que aún suena, no quieres que la lectura de apertura lo corte, pero sí que los movimientos
> posteriores interrumpan. Pásalo como quinto argumento:
> `Cursor.announce(scene, :bless, idx, true, false) { ... }` — la PRIMERA lectura de un cursor fresco/reseteado
> (cuando `slot` está `pending?`) usa `false` (encola), y cada movimiento después usa `true` (interrumpe).
> `Cursor.reset(holder, slot)` fuerza que la siguiente lectura hable aunque el índice no cambie (útil al
> reabrir una escena con el cursor en la misma entrada). Para gatear trabajo arbitrario sin hablar están
> `Cursor.changed?`/`on_change`/`pending?`.

> **Otros ejemplos del repo con este mismo patrón**, por si quieres leer código real:
> `games/relict/plates.rb` (`rewriteArcyPlates`, índice por argumento),
> `core/battle/skyflyer/dbk_selectors.rb` (`pbUpdateBallSelection`/`pbUpdateBattlerSelection`, dedup por
> índice/par), y el helper `Menus.poll_sprite_menu` que comparten el Neo PauseMenu, el Ready Menu y el
> selector de tema del Pokégear.

Si el juego **no llama a ningún método** al mover (muta un ivar dentro de un loop propio), usa
`poll_each_frame` (un bloque que corre una vez por frame en toda escena). Para el caso típico "escena con
`@index` + array de entradas" existe el helper `Menus.poll_sprite_menu(scene, items_ivar, dedup_slot)`
(`core/menus/menus.rb:16`), que ya lee `@index`, valida el rango y deduplica con `Cursor`; le pasas el ivar
del array y un `slot` de dedup, y el bloque convierte la entrada enfocada en texto:

```ruby
PokeAccess::Game.define("<juego>") do
  poll_each_frame do
    sc = $scene
    next unless sc.is_a?(MiSceneSpriteBased)   # gate por clase
    PokeAccess::Menus.poll_sprite_menu(sc, :@entries, :mi_menu_last) do |entry|
      texto_de_la_opcion(entry)
    end
  end
end
```

Si tu escena se desvía del patrón (índice en otro ivar, clave compuesta), llama a `Cursor.announce` a mano
como en el ejemplo de `updateCursor` de arriba.

> **Dedup por instancia (vía `Cursor`), no a nivel de módulo.** El estado de dedup vive en la escena
> (`holder`), así que muere con ella y la pantalla vuelve a leer al reabrirse en el mismo estado. Esta es una
> convención dura del repo: un dedup a nivel de módulo deja la pantalla muda al reabrirla en el mismo estado.
> `Cursor` centraliza esto (antes cada lector reinventaba su propio `@access_*` y rompía los casos sutiles:
> escena fresca que debe releer el mismo índice, clave-tupla `[página, índice]`, texto que cambió sin cambiar
> el índice).

---

## 3. Cuando `Game.define` no basta: bajar a `Hooks`

`Game.define` (`after`/`before`/`around`/`poll_each_frame`) cubre casi todo. Dos casos obligan a usar
directamente `PokeAccess::Hooks` (`core/input/hooks.rb`), porque el original del método que enganchas aloja
sincrónicamente OTROS lectores hookeados y un `after` normal (que corre bajo la guarda de reentrancia) los
silenciaría.

**El porqué en una frase:** el juego es mono-hilo; `Hooks` lleva una pila con el nombre del método cuyo
original está corriendo, y salta cualquier hook anidado de nombre DISTINTO (para que un `after` que llame
internamente a otro método hookeado no lo re-anuncie ni le robe el dedup). Eso está bien para un *anunciante
atómico* (su propio cuerpo es la voz), pero es fatal para un método que DELEGA el anuncio a los lectores que
conduce por dentro. Detalle completo en [04_PATCHING_AND_HOOKS.md](04_PATCHING_AND_HOOKS.md).

### 3a. `hook_container` — un contenedor modal que delega el anuncio

Un bucle modal o abre-escena que no habla él mismo, sino que conduce métodos hookeados (el `drawPage` del
pokédex, el `drawPageOne` del resumen, el `selected=` del panel de party, el menú de comandos de combate).
Su original debe correr SIN la guarda o esos lectores internos enmudecen:

```ruby
PokeAccess::Hooks.after_hook("MiScene", :pbStartScene, :hook_container => true) do |scene, _r, _a|
  # normalmente vacío: el anuncio lo hacen los lectores que la escena conduce por dentro
end
```

### 3b. `frame_hook` — un driver por-frame que anida un bucle modal entero

Un método que el motor llama CADA frame y que puede alojar dentro un bucle modal completo. El caso canónico
es `Game_Player#update`: en gen-6, pisar hierba lanza el combate salvaje DESDE DENTRO de `update`
(`Scene_Map#update -> $game_player.update -> encounter -> el combate entero`). Guardarlo fijaría `:update` en
la pila durante todo el combate y cada lector de batalla (mensajes, menú de comandos, movimientos) se saltaría
como anidado — el bug clásico "los combates salvajes son mudos, los de entrenador leen" (el de entrenador
corre desde el intérprete del mapa, no desde el player). `frame_hook` corre el original SIN guarda y el cuerpo
DESPUÉS (un poller que lee el estado del frame ya actualizado, p.ej. la nueva casilla para el audio espacial):

```ruby
PokeAccess::Hooks.frame_hook("Game_Player", :update) do |player, _args|
  # poller: lee el estado ya actualizado del frame; sin valor de retorno que usar
end
```

`frame_hook(cname, meth)` es internamente `after_hook(cname, meth, :hook_container => true)` con forma de
poller. Ambos son 1.8.7-safe. Regla práctica: si tu `after` engancha algo que abre una escena/menú con sus
propios lectores, o un método por-frame que puede lanzar un combate/menú entero, usa `hook_container`/
`frame_hook`; para un anunciante atómico, el `after` normal de `Game.define` es lo correcto.

---

## 4. Añadir un puzzle

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

## 5. Crear un perfil de juego nuevo

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
`check187.py`** (sin `&.`, sin `->`, sin `&:sym`, sin `round/ceil/floor(arg)`, etc. — ver [08_RUBY_FUNDAMENTALS.md](08_RUBY_FUNDAMENTALS.md)).
Añade el perfil a la lista de perfiles que carga el CI (`.github/workflows/ci.yml`).

---

## 6. Lectores de plugins del fork de Sky (skyflyer / DBK)

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

## 7. Reglas que evitan los errores recurrentes

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

## 8. Diagnosticar una pantalla muda (Ctrl+Alt+F8 / Ctrl+Alt+F9)

Cuando un colaborador (o un usuario) reporta "esta pantalla no lee nada", este es el flujo, sin abrir el
`Scripts.rxdata` del juego:

1. **Ctrl+Alt+F8** activa/desactiva el mod entero (para confirmar rápido que el mod está cargado y que el
   problema es esa pantalla, no el arranque).
2. Entra en la pantalla muda y pulsa **Ctrl+Alt+F9**: anexa a `accessibility/data/diag.txt` (con fecha) un
   bloque con dos partes — los timings de `perf` y la sección `runtime introspection` del `$scene` actual.

La sección `runtime introspection` te da todo lo necesario para escribir el hook:

- `$scene=<clase>` con `methods=[...]` — los **candidatos a enganchar** (busca un `update`/`refresh`/
  `pbUpdate`/`selectButton`/`showTexts` que corra en cada movimiento del cursor).
- `ivars: [@index=3, @buttons=Array(8), ...]` — **dónde está el índice y dónde los datos**.
- `@sprites keys=[...]` con la clase e índice de cada ventana — para menús basados en `@sprites`.
- `live_selectables=[...]` — ventanas `Window_Selectable`/`Window_Command` vivas y visibles, incluso si
  no son `Window_DrawableCommand` (si la pantalla aparece aquí, casi seguro el core ya la lee y el
  problema es otro: un install desfasado, ver sección 7).

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
