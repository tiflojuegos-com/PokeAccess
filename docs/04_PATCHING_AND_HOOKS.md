# Patching & Hooks (Sistema de Enganches)

## Concepto Fundamental

**Hooking** es el acto de insertar código personalizado en métodos existentes sin modificar los archivos originales. Es como "interceptar" una llamada a método para:

1. Ejecutar lógica ANTES (before hook)
2. Ejecutar lógica DESPUÉS (after hook)
3. Reemplazar el método completamente (override)

## ¿Por Qué es Crítico?

PokeEssentialsAccess **NO MODIFICA** los archivos de Essentials. En su lugar:

```
Essentials original          PokeAccess
└─ class PokeBattle_Scene    ├─ Define antes_hooks en memoria
   └─ def pbDisplayMessage   ├─ Ejecuta: PokeAccess.speak()
      └─ Mostrar ventana     ├─ Llama método original
                             └─ Actualiza UI
```

**Ventajas**:
- Juego original intacto
- Múltiples patches pueden coexistir
- Fácil remover PokeEssentialsAccess (solo delete carpeta)
- Funciona con cualquier versión de Essentials

## Sistema de Hooks de PokeEssentialsAccess

**Ubicación**: `core/input/hooks.rb`

### Arquitectura

El motor encadena los hooks de un mismo método como una **cebolla (onion) de middlewares**: cada
registro envuelve al anterior alrededor del método original, así una función nueva nunca desactiva en
silencio un hook existente.

```ruby
module PokeAccess::Hooks
  @chains = {}   # { "Clase#metodo" => [middleware1, middleware2, ...] }
  @missing = []  # "Clase#metodo" cuya clase existe pero el método no (típicamente un typo)

  # Núcleo: registra un middleware alrededor de un método y encadena con los demás.
  def self.wrap(cname, meth, &mw); ...; end

  def self.before_hook(cname, meth, &body)         # yield (instancia, args)
  def self.after_hook(cname, meth, opts = {}, &body) # yield (instancia, resultado, args); opts[:hook_container]
  def self.frame_hook(cname, meth, &body)          # yield (instancia, args); driver por-frame (sin guarda)
  def self.around_hook(cname, meth, &body)         # yield (instancia, call_next, args)
  def self.wrap_global(name, tag, timing = :after, &body)  # método top-level (Object)
  def self.wrap_kernel(name, tag, timing = :before, &body) # Kernel.foo O top-level; :before/:after/:around
end
```

Todos los métodos son 1.8.7-safe (los juegos gen-6 corren un Ruby antiguo).

### Uso Básico

#### Before Hook (Interceptar Entrada)

```ruby
# Cuando PokeBattle_Scene.pbDisplayMessage se llama:
# 1. Ejecuta nuestro código
# 2. Luego ejecuta el método original

PokeAccess::Hooks.before_hook("PokeBattle_Scene", :pbDisplayMessage) do |scene, args|
  # scene = instancia de PokeBattle_Scene
  # args = argumentos pasados a pbDisplayMessage ([mensaje])
  
  # Hablar el mensaje ANTES de mostrarlo gráficamente
  PokeAccess.speak(args[0], false)
end
```

#### After Hook (Reaccionar a Resultado)

```ruby
# Cuando FightMenuDisplay.setIndex se llama:
# 1. Se ejecuta el método original
# 2. Ejecuta nuestro código

PokeAccess::Hooks.after_hook("FightMenuDisplay", :setIndex) do |disp, result, args|
  # disp = instancia de FightMenuDisplay
  # result = lo que devolvió setIndex
  # args = argumentos originales
  
  # Leer el movimiento que ahora está seleccionado
  move = disp.instance_variable_get(:@battler).moves[disp.index]
  PokeAccess.speak(move.name)
end
```

## Implementación Interna

### Ruby Method Aliasing

La técnica base es **alias_method**: se guarda el método original bajo un alias y se redefine el
método con `define_method`, llamando al alias por dentro.

```ruby
class MiClase
  def metodo_original
    "resultado"
  end
end

# Guardar el original bajo un alias
MiClase.send(:alias_method, :metodo_original__orig, :metodo_original)

# Redefinir llamando al alias
MiClase.send(:define_method, :metodo_original) do |*args, &blk|
  puts "ANTES"
  result = send(:metodo_original__orig, *args, &blk)
  puts "DESPUÉS: #{result}"
  result
end
```

### Cómo lo Implementa PokeEssentialsAccess

`wrap` no redefine de cero cada vez: la PRIMERA vez crea el alias (con nombre por-clase, p.ej.
`update__pa_orig_Battle__Scene`) y un `define_method` que recorre la **cadena de middlewares**; cada
hook posterior solo añade su middleware a la cadena. Simplificado:

```ruby
module PokeAccess::Hooks
  def self.wrap(cname, meth, &mw)
    k = PokeAccess.const_at(cname)   # resolución 1.8.7-safe (no Object.const_defined? con "::")
    return if k.nil?
    unless k.method_defined?(meth)
      @missing << "#{cname}##{meth}"   # clase existe, método no => probable typo
      return
    end
    key = "#{cname}##{meth}"
    fresh = !@chains.has_key?(key)
    (@chains[key] ||= []).push(mw)
    return unless fresh               # ya envuelto: basta con añadir a la cadena
    orig = "#{meth}__pa_orig_#{cname.gsub(/[^a-zA-Z0-9]/, '_')}".to_sym
    k.send(:alias_method, orig, meth)
    chains = @chains
    k.send(:define_method, meth) do |*args, &blk|
      call = lambda { send(orig, *args, &blk) }      # el original, al fondo de la cebolla
      chains[key].reverse_each do |w|                # envolver cada middleware alrededor
        nxt = call
        call = lambda { w.call(self, nxt, args) }
      end
      call.call
    end
  end
end
```

`before_hook`/`after_hook` son middlewares finos sobre `wrap`: el "before" corre el cuerpo y luego
`nxt.call`; el "after" hace `r = nxt.call`, corre el cuerpo con `r`, y devuelve `r`. El cuerpo va
envuelto en `run_body`, que **traga la excepción** (un lector que peta no rompe el juego) pero **loguea
el primer fallo** por método al marker, para que un método mal escrito no quede mudo sin diagnóstico.

**Lo que sucede en memoria**:

```
Antes del hook:
PokeBattle_Scene#pbDisplayMessage → código original

Después del hook:
PokeBattle_Scene#pbDisplayMessage 
├─ [HOOK] PokeAccess.speak(msg)
├─ [ORIGINAL] mostrar ventana
└─ [RETURN] resultado
```

## Guarda de reentrancia (por qué existe)

El juego es mono-hilo. `Hooks` mantiene una pila de módulo (`@active`) con los NOMBRES de los métodos
cuyo ORIGINAL está corriendo ahora mismo. Con eso resuelve un problema sutil de los `after_hook`:

- `nested_other?(meth)` (`hooks.rb:34`) devuelve `true` si hay algo en la pila y la cima NO es `meth`.
- El dispatcher de `wrap` (`hooks.rb:74`): si la llamada es una entrada anidada a un método hookeado con
  nombre DISTINTO al de la cima, se salta la cadena y va directo al original.

¿Para qué? Un `after_hook` cuyo original llama SINCRÓNICAMENTE a OTRO método hookeado (p.ej. en la era
GameData `set_party_index` invoca por dentro a `refresh`) no debe dejar que el hook interno hable y
consuma el dedup del externo: el `after_hook` EXTERNO, cuando el original vuelve, es el anunciante
autoritativo. Una llamada anidada del MISMO nombre SÍ pasa (un hijo que llega a su padre hookeado vía
`super` dispara ambos hooks: la cebolla documentada).

`guarded(meth)` (`hooks.rb:40`) empuja `meth`, hace `yield` y SIEMPRE hace `pop` (`ensure`): un original
que lanza nunca deja hooks anidados mudos para siempre. Por defecto, un `after_hook` corre su original
BAJO esta guarda.

### Cuándo un hook debe correr SIN guarda: contenedores y drivers por-frame

La guarda es correcta SOLO para **anunciantes atómicos** (métodos cuyo propio cuerpo es la voz). Dos
clases de hook tienen que correr su original SIN guarda o silencian a los lectores que hablan:

- **CONTENEDOR — `after_hook(..., :hook_container => true)`**: un loop modal o abre-escena que DELEGA el
  anuncio a métodos hookeados que él conduce por dentro. Ejemplos reales: la fase de comandos de combate
  (`pbShowCommands`/`pbCommandMenu` conducen `CommandMenuDisplay#index=` y `FightMenuDisplay#setIndex`);
  los abre-escenas (`pbScene`/`pbStartScene`/`main` conducen el `drawPage` del pokédex, el `drawPageOne`
  del resumen, el `selected=` del panel de party, los lectores del mapa). En `core/battle/gen6/battle_g6.rb:21`,
  `pbUpdateSelected` es contenedor porque conduce los `index=` hookeados del display de comandos/movimientos.

- **DRIVER por-frame — `frame_hook`**: un método que el motor llama cada frame y que puede alojar
  sincrónicamente un loop modal anidado ENTERO. Internamente es `after_hook(cname, meth, :hook_container => true)`
  con el cuerpo después (un poller no usa el valor de retorno). Yields `(instancia, args)`.

```ruby
# core/audio/audio3d.rb:537 y core/nav/locator.rb:517 — mismo método, dos features:
PokeAccess::Hooks.frame_hook("Game_Player", :update) do |_p, _a|
  # sondear el estado del frame recién actualizado (p.ej. el tile nuevo del jugador)
end
```

**El caso del combate salvaje en gen-6** (por qué `frame_hook` existe): en gen-6, pisar hierba lanza el
combate salvaje DESDE DENTRO de `Game_Player#update` (`Scene_Map#update -> $game_player.update -> encounter
-> el loop de combate entero`). Si se enganchara `update` con un `after_hook` normal, `:update` quedaría
fijado en la pila durante todo el combate y cada lector de batalla (mensajes, menú de comandos,
movimientos) se saltaría como `nested_other?`. El síntoma era exacto: "los combates salvajes son mudos,
los de entrenador leen" — un combate de entrenador corre desde el intérprete del mapa, no desde el player,
por eso no le afectaba. `frame_hook` corre el original sin guarda y arregla esto.

Por defecto es atómico (guardado): un hook que no dice nada mantiene el comportamiento seguro. Los cuerpos
de `before_hook` corren SIEMPRE antes del original y nunca guardan su original.

## Casos de Uso Prácticos

### Caso 1: Lectura de Mensajes de Batalla

**Archivo**: `core/battle/gen6/battle_g6.rb`

```ruby
# En batalla, cuando se muestra un mensaje:
PokeAccess::Hooks.before_hook("PokeBattle_Scene", :pbDisplayMessage) do |scene, args|
  PokeAccess::Battle.set_battle(scene.instance_variable_get(:@battle))
  # Hablar el mensaje SIN interrumpir el flujo gráfico (speak_clean = limpiar códigos + hablar)
  PokeAccess.speak_clean(args[0], false)
end

# Flujo:
# 1. Código de Essentials: pbDisplayMessage("¡Ataque crítico!")
# 2. Hook intercepta: PokeAccess.speak("Ataque crítico!")
# 3. Método original: Mostrar ventana gráficamente
# 4. El jugador escucha + ve el mensaje simultáneamente
```

### Caso 2: Selección de Movimiento en Batalla

**Archivo**: `core/battle/gen6/battle_g6.rb`

```ruby
PokeAccess::Hooks.after_hook("FightMenuDisplay", :setIndex) do |disp, _r, _a|
  b = disp.instance_variable_get(:@battler)
  idx = disp.instance_variable_get(:@index)
  
  if b && b.moves[idx] && b.moves[idx].id != 0
    m = b.moves[idx]
    # Hablar nombre del movimiento + PP
    text = "#{m.name}. PP: #{m.pp}/#{m.totalpp}"
    PokeAccess.speak(text, true)
  end
end

# Cuando el jugador navega movimientos con flechas:
# 1. Se ejecuta FightMenuDisplay#setIndex
# 2. Hook DESPUÉS: Lee qué movimiento está seleccionado
# 3. PokeAccess.speak() lo anuncia al jugador
```

### Caso 3: Menú de Pausa basado en sprites (sin ventana de comandos)

**Archivo**: `core/menus/neo_pausemenu.rb`

Algunos menús no usan `Window_CommandPokemon`; son sprites con el índice en un ivar privado. No hay un
`index=` que enganchar, así que se engancha el `update` de la escena y se sondea el índice por frame
(patrón `Menus.poll_sprite_menu`):

```ruby
# El menú "Neo" no tiene ventana de comandos: se vigila su escena. poll_sprite_menu recibe el ivar de la
# lista, un slot de dedup PELADO (sin arroba: Cursor compone él mismo el ivar @access_cur_<slot> sobre la
# escena) y un bloque que da la etiqueta de la entrada enfocada.
PokeAccess::Hooks.after_hook("PokemonMenu_Scene", :update) do |scene, _r, _a|
  if defined?(MenuHandlers)
    PokeAccess::Menus.poll_sprite_menu(scene, :@entries, :neo_last) do |entry|
      (MenuHandlers.getName(entry) rescue entry.to_s)
    end
  end
end
```

Para el caso normal (una ventana de comandos que sí tiene `index=`), lo correcto es `screen_reader`
(ver [14_EXTENDING.md](14_EXTENDING.md) §2a).

## Manejo de Errores

### Validación de Clases

`before_hook`/`after_hook`/`around_hook` delegan en `wrap`, y es `wrap` quien comprueba la existencia
de la clase con `PokeAccess.const_at` (resolución 1.8.7-safe, no `Object.const_defined?` con `"::"`) antes
de atar nada. Una clase ausente es variación normal entre juegos y se ignora en silencio; un método ausente
sobre una clase presente sí se anota en `Hooks.missing` (casi siempre un typo). No hay que reimplementar esa
comprobación en cada hook:

```ruby
# Resultado:
# - Gen-6 + hook de clase v21: no pasa nada (NO-OP, la clase no existe)
# - v21 + hook de clase v21: funciona
```

### Recuperación de Errores en Hooks

El cuerpo de cada hook ya corre dentro de `run_body`, que traga la excepción (para que un lector con
fallo nunca rompa el juego) y registra el PRIMER fallo por método en el marker (deduplicado). Por eso el
cuerpo NO necesita su propio `begin/rescue`: basta escribir el lector:

```ruby
PokeAccess::Hooks.after_hook("PokeBattle_Scene", :pbDisplayMessage) do |scene, result, args|
  PokeAccess.speak(args[0])   # si lanza, run_body lo traga y anota el primer fallo
end
```

## Registro de Hooks Fallantes

**Archivo**: `core/input/hooks.rb` (método `missing`)

`missing` NO reporta clases ausentes (eso es variación normal entre juegos y se ignora a propósito).
Reporta lo contrario: bindings cuya **clase existe pero el método no** — casi siempre un nombre de
método mal escrito.

```ruby
def self.missing; @missing; end
# @missing se va llenando dentro de wrap cuando la clase existe pero method_defined?(meth) es false.

# En boot.rb:
miss = (PokeAccess::Hooks.missing rescue [])
log("[diag] enganches sin metodo: #{miss.join(', ')}") if miss && !miss.empty?

# Si esto reporta algo, casi seguro es un typo en el nombre del método de un hook:
# la clase se encontró, pero el método indicado no existe en ella.
```

## Avanzado: Modificación de Comportamiento

### Cambiar Valor de Retorno

```ruby
PokeAccess::Hooks.after_hook("Passability", :move_possible?) do |obj, result, args|
  # En lugar de devolver el resultado original...
  # Implementar lógica personalizada
  
  # Pero normalmente el hook solo LEE, no modifica
end
```

### Bloquear o sustituir la ejecución del original

No hay un `throw :skip_original`. Para decidir si el original corre (o sustituirlo), se usa
`around_hook`: el cuerpo recibe `call_next` y controla si lo llama o no.

```ruby
PokeAccess::Hooks.around_hook("Puzzle", :onTile) do |puzzle, call_next, args|
  if special_case?
    # No llamamos a call_next => el método original NO se ejecuta
    PokeAccess.speak("...")
  else
    call_next.call   # ejecuta el original (y el resto de la cadena)
  end
end
```

> `around_hook` es el único que NO traga la excepción del cuerpo: como puede elegir legítimamente no
> ejecutar el original, su primer fallo se loguea y se relanza (preserva la semántica del `around`).

### Enganchar funciones globales (no de clase)

Los hooks de clase no alcanzan las funciones top-level de Essentials (`pbDisplayMail`,
`pbShowCommandsWithHelp`, etc.). Para eso hay dos helpers:

- `wrap_global(name, tag, timing = :after)` (`hooks.rb:161`): envuelve un método top-level de `Object`.
  `timing :before` corre el bloque antes del original (para llamadas bloqueantes cuyo anuncio debe
  precederlas), con `nil` en el valor de retorno; `:after` corre después y pasa el resultado. El bloque
  recibe `(args_array, return_value)`. No-op si el método no existe o ya está envuelto.
- `wrap_kernel(name, tag, timing = :before)` (`hooks.rb:197`): para funciones que unos juegos definen como
  singleton de `Kernel` (`def Kernel.foo`, estilo gen-6) y otros como top-level de `Object` (`def foo`,
  estilo moderno) — `pbShowCommandsWithHelp` es una de ellas. Prueba el singleton de `Kernel` primero y si
  no cae a `wrap_global`. `timing :before`/`:after` → bloque `(args_array, return_value)`; `:around` →
  bloque `(args_array, call_next)` y DEBE llamar `call_next` (devuelve el resultado del original).

```ruby
# core/field/mail.rb: leer el correo antes de que aparezca su tarjeta modal (:before).
PokeAccess::Hooks.wrap_global("pbDisplayMail", "hook_mail", :before) { |args, _r| PokeAccess.say_mail(args[0]) }
```

## Diferencias: before vs after

| Aspecto | before | after |
|---------|--------|-------|
| **Cuándo** | Antes del método original | Después del método original |
| **Acceso** | Solo argumentos | Argumentos + resultado |
| **Caso de uso** | Preparar, loguear entrada | Reaccionar a resultado |
| **Modificación** | Puede modificar args | No puede cambiar args |
| **Ejemplo** | Hablar antes de mostrar | Leer UI después de actualizar |

## Patrones Comunes

### Patrón: Lectura Deduplicada

```ruby
PokeAccess::Hooks.after_hook("Window", :index=) do |window, _r, args|
  idx = args[0]
  
  # Solo hablar si el índice CAMBIÓ
  # (evitar lecturas duplicadas si el usuario presiona la flecha varias veces)
  if idx != window.instance_variable_get(:@access_last_index)
    window.instance_variable_set(:@access_last_index, idx)
    PokeAccess.speak(get_label(idx))
  end
end
```

### Patrón: Información Contextual

```ruby
PokeAccess::Hooks.before_hook("BattleScreen", :draw) do |scene, args|
  # Guardar contexto para que otros módulos lo lean
  PokeAccess::Info.set_info(:battle_turn, scene.turn_count)
  PokeAccess::Info.set_info(:active_pokemon, scene.active_battler)
end
```

### Patrón: Condicional por Engine

```ruby
PokeAccess::Hooks.before_hook("PokeBattle_Scene", :pbDisplayMessage) do |scene, args|
  # En gen-6
  PokeAccess.speak(args[0]) if PokeAccess::Engine.gen6?
end

PokeAccess::Hooks.before_hook("Battle::Scene", :pbMessageWindow) do |scene, args|
  # En la era GameData
  PokeAccess.speak(args[0]) if PokeAccess::Engine.gamedata?
end
```

> En la práctica casi nunca hace falta ramificar por engine: registra cada hook donde la CLASE existe
> (el hook es NO-OP si no), y para lo que difiere dentro de una misma clase, gatea por CAPACIDAD con
> `Engine.has?("Clase#metodo")` en vez de por versión. Así un fork que backportee el método se activa solo.

### Patrón: Gate por capacidad (recomendado para features opcionales)

```ruby
# Solo si esta clase+método existen (vanilla v22, Sky que lo backportee, o una versión futura que lo conserve):
if PokeAccess::Engine.has?("Battle::Scene#pbUpdateBattlerInfo")
  PokeAccess::Hooks.after_hook("Battle::Scene", :pbUpdateBattlerInfo) do |scene, _r, args|
    # ...
  end
end
```

### Patrón: Lectura de cursor deduplicada (Cursor)

La UI re-afirma la selección cada frame, así que un lector de cursor debe hablar SOLO cuando el foco
cambia. No abras tu propio ivar `@access_*`: usa la primitiva `Cursor`.

```ruby
PokeAccess::Hooks.after_hook("MiVisuals", :refresh_on_index_changed) do |vis, _r, _a|
  idx = (vis.index rescue nil)
  PokeAccess::Cursor.announce(vis, :mi_lista, idx) { texto_de(vis, idx) }  # habla solo si idx cambió
end
# Al (re)abrir la escena, para que relea el mismo índice:
PokeAccess::Hooks.before_hook("MiScene", :pbStartScene) { |s, _a| PokeAccess::Cursor.reset(s, :mi_lista) }
```

La key puede ser un índice, un texto o una tupla (`[page, party_index]`). El `holder` es la instancia
(estado por escena, muere con ella), o `nil` para una tabla global por slot.

## Debugging Hooks

### Logging de Hooks Ejecutados

```ruby
PokeAccess::Hooks.before_hook("MyClass", :my_method) do |obj, args|
  puts "HOOK: MyClass#my_method llamado con #{args.inspect}"
  PokeAccess.write_marker("Hook ejecutado\n")
end
```

### Inspeccionar Estado

```ruby
PokeAccess::Hooks.after_hook("PokeBattle_Scene", :pbDisplayMessage) do |scene, result, args|
  # Escribir diagnóstico
  File.open("diag.txt", "a") do |f|
    f.write("Mensaje mostrado: #{args[0]}\n")
    f.write("Batalla: #{scene.instance_variable_get(:@battle).inspect}\n")
  end
end
```

## Limitaciones y Consideraciones

### 1. **Rendimiento**
Cada hook añade overhead (llamada a bloque, instance_variable_get). Optimizar:
- Caché resultados
- Reduce hooks por frame
- Evita loops

### 2. **Orden de Ejecución**
Si múltiples módulos registran hooks en el mismo método:
```ruby
# Ambos se ejecutan, pero ¿en qué orden?
PokeAccess::Hooks.after_hook("Window", :update) { puts "A" }
PokeAccess::Hooks.after_hook("Window", :update) { puts "B" }

# Orden de registro (FIFO)
# OUTPUT: A, B
```

### 3. **Compatibilidad con Otros Mods**
Si otro mod también usa hooks:
- Podrían interferir
- Generalmente OK si usan métodos diferentes
- Requiere comunicación con el autor del mod

## Referencias

- [Hooks Module](../core/input/hooks.rb) - Implementación (motor de cadena/middleware)
- [Battle G6 Hooks](../core/battle/gen6/battle_g6.rb) - Ejemplos gen-6
- [Battle V21 Hooks](../core/battle/v21/battle_v21.rb) - Ejemplos era GameData
- [Menu Framework](../core/menus/menus.rb) - def_extractor / poll_sprite_menu
- [Guía de extensión](14_EXTENDING.md) - Cómo añadir tus propios hooks/lectores

## Próximo

- [Data API](05_DATA_API.md) - Acceso a datos
- [Pathfinding](06_PATHFINDING.md) - Navegación
