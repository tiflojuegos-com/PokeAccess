# Pathfinding - Búsqueda de Rutas

## Concepto: Navegación Asistida

**Pathfinding** es encontrar el camino más corto entre dos puntos en un mapa. En PokeEssentialsAccess:

1. **Jugador** presiona tecla para ir a destino
2. **Pathfinder** calcula ruta desde jugador hasta NPCs/objetos
3. **Auto-walker** sigue la ruta automáticamente
4. **Audios 3D** indican progreso

## El Desafío

Essentials no expone un pathfinder publico. Solución: Implementar **A* Search** + **HPA*** + **flood reachability**

## Algoritmo Principal: A* Search

### ¿Qué es A*?

Algoritmo de búsqueda de caminos que encuentra la ruta óptima rápidamente:

```
Inicio (player)
  ├─ Explora vecinos cercanos
  ├─ Calcula: costo_actual + distancia_heurística_al_destino
  ├─ Expande nodos con menor costo primero
  └─ Llega a destino con ruta óptima

Ventaja sobre Dijkstra: La heurística lo acelera 100x
```

### Implementación en Ruby

**Ubicación**: `core/nav/pathfinder.rb`

```ruby
module PokeAccess::Pathfinder
  # Empaquetador de coordenadas: (x,y) → único entero
  PKEY_STRIDE = 100000
  
  def self.pkey(x, y)
    x * PKEY_STRIDE + y
  end
  
  # Para recuperar (x,y) de una clave se divide entre PKEY_STRIDE (inline en el código real;
  # no hay un método unpack_key): x = k / PKEY_STRIDE ; y = k % PKEY_STRIDE
  
  # Cuatro direcciones ortogonales: [dx, dy, código_RPG_direction]
  DIRS = [
    [0, -1, 8],  # Arriba
    [0, 1, 2],   # Abajo
    [-1, 0, 4],  # Izquierda
    [1, 0, 6]    # Derecha
  ]
end
```

**¿Por qué empaquetador?**
- Hash con keys (x,y) sería lento
- Hash con key=entero es O(1) muy rápido
- Un único entero por coordenada: `x * 100000 + y`

### A* en Pseudocódigo

> Esto es **pseudocódigo ilustrativo** del algoritmo, no la firma real. La API pública es
> `Pathfinder.find_path(tx, ty)` — toma SOLO el destino; el origen es `$game_player`. Aquí se muestran
> start/goal explícitos solo para explicar A*.

```ruby
def find_path(start_x, start_y, goal_x, goal_y)   # (pseudocódigo; la firma real es find_path(tx, ty))
  open_set = BinaryHeap.new    # Nodos por explorar (ordenados por costo)
  g_score = {}                 # Costo desde inicio
  f_score = {}                 # Costo total (g + heurística)
  
  # Manhattan distance heurística
  h = lambda { |x, y| (x - goal_x).abs + (y - goal_y).abs }
  
  # Inicio
  start_key = pkey(start_x, start_y)
  open_set.push(start_key, 0)
  g_score[start_key] = 0
  f_score[start_key] = h.call(start_x, start_y)
  
  while !open_set.empty?
    current = open_set.pop
    x, y = current / PKEY_STRIDE, current % PKEY_STRIDE
    
    return reconstruct_path(current) if x == goal_x && y == goal_y
    
    DIRS.each do |dx, dy, direction|
      nx, ny = x + dx, y + dy
      next unless passable_at?(nx, ny, direction)
      
      tentative_g = g_score[current] + 1
      neighbor_key = pkey(nx, ny)
      
      if tentative_g < (g_score[neighbor_key] || Float::INFINITY)
        g_score[neighbor_key] = tentative_g
        f_score[neighbor_key] = tentative_g + h.call(nx, ny)
        open_set.push(neighbor_key, f_score[neighbor_key])
      end
    end
  end
  
  nil  # No hay camino
end
```

## Complicaciones: Ledges

En Pokémon, el jugador puede **saltar ledges** (acantilados):

```
┌─────┐
│ end │     <- Tierra alta
└─────┘
  (fall)    <- El jugador salta aquí automáticamente
┌─────┐
│start│     <- Tierra baja
└─────┘
```

### Detección de Ledges

```ruby
# El bit de "saltable hacia" depende de la dirección. El código real usa un mapa dirección->bit
# (no una sola constante LEDGE_BIT):
LEDGE_OPP_BIT = { 2 => 0x08, 8 => 0x01, 4 => 0x04, 6 => 0x02 }

def self.ledge_jump(cx, cy, dx, dy, d)
  nx = cx + dx
  ny = cy + dy
  return nil unless PokeAccess::Terrain.ledge_at?(nx, ny)   # ledge vive en Terrain
  return nil unless ledge_dir_ok?(nx, ny, d)                # ¿saltable en esa dirección?

  # Landing dos tiles más allá: válido y pisable (passable? real del juego, no un standable_at? propio)
  lx = cx + 2 * dx
  ly = cy + 2 * dy
  return nil unless $game_map.valid?(lx, ly) && $game_player.passable?(lx, ly, 0)

  [lx, ly]
end
```

## Optimizaciones: Caché de Rutas

### Problema: Passability es Lento

```ruby
# En gen-6, $game_player.passable? es LENTO
# Recalcula en cada frame si queremos re-routear

# Si hay 100 eventos:
# 100 pathfinds × 10000 tiles explorados × passable? = MILLONES de llamadas
```

### Solución: Memoización

```ruby
module PokeAccess::Pathfinder
  @pcache = {}        # Caché
  @pcache_state = nil # Estado actual del mapa
  
  def self.passable_at?(cx, cy, d)
    # Si route_cache está OFF, usa pasable directo
    return passable_no_cache?(cx, cy, d) unless config.route_cache
    
    # Construir estado actual
    st = [
      $game_map.map_id,
      $PokemonGlobal.surfing,
      $PokemonGlobal.diving
    ]
    
    # ¿Cambió el estado? Limpiar caché
    if @pcache_state != st
      @pcache = {}
      @pcache_state = st
    end
    
    # Buscar en caché
    k = pkey(cx, cy) * 16 + d
    v = @pcache[k]
    return v unless v.nil?
    
    # No en caché: calcular y guardar
    @pcache[k] = passable_no_cache?(cx, cy, d)
  end
end
```

**Impacto**: 100x más rápido si route_cache ON

## Optimizaciones: HPA* (Hierarchical Pathfinding)

**Para mapas muy grandes** (100x100+ tiles):

```ruby
# En lugar de explorar 10000 tiles:
# 1. Dividir mapa en clusters (8x8 tiles)
# 2. Buscar entre clusters primero (mucho más rápido)
# 3. Luego detalle local

@hpa = nil  # Gráfico abstracto

def self.hpa_path(start, goal)
  if @hpa.nil?
    # Construir gráfico jerárquico
    @hpa = build_hpa_graph()
  end
  
  # Buscar en gráfico abstracto
  cluster_path = a_star(start.cluster, goal.cluster, @hpa)
  
  # Convertir a tiles
  # ...
end
```

## Detección de Reachability

**Problema**: ¿Es realmente alcanzable el objetivo?

```ruby
# Esquema. Métodos reales: el flood de alcanzables es Pathfinder.reachable_tiles (sin args, desde el
# jugador); Pathfinder.reachable_set lo cachea por tile del jugador (lo comparten el filtro
# hide-unreachable del Locator y el test de línea de vista del audio posicional). Pathfinder.reach NO es
# esto: es solo el getter de la DISTANCIA máxima (Config.route_reach) que acota el flood.
# find_path(tx, ty) decide solo por dentro: para un destino cercano (< FLOOD_MIN) un A* directo es más
# barato que un flood completo.
FLOOD_MIN = 24  # Distancia bajo la cual find_path prefiere A* directo en vez de flood

def self.reachable_tiles
  px = $game_player.x
  py = $game_player.y

  # Flood fill (BFS) desde el jugador, acotado por reach (route_reach) y un tope de nodos.
  reachable = { pkey(px, py) => true }
  queue = [[px, py]]; head = 0

  while head < queue.length
    x, y = queue[head]; head += 1

    DIRS.each do |dx, dy, d|
      nx, ny = x + dx, y + dy
      nk = pkey(nx, ny)
      next if reachable[nk]
      next unless passable_at?(nx, ny, d)
      next if (nx - px).abs + (ny - py).abs > reach   # acotado por la distancia configurada
      reachable[nk] = true; queue.push([nx, ny])
    end
  end

  reachable
end
```

## Invalidación de Caché

```ruby
def self.invalidate_cache(force = false)
  now = PokeAccess.clock
  
  # Throttle: máximo una invalidación cada 2 segundos
  # (Muchos eventos pueden cambiar passability rapidamente)
  return if !force && @last_invalidate && (now - @last_invalidate) < 2.0
  
  @last_invalidate = now
  @pcache = {}           # Limpiar caché de passability
  @pcache_state = nil
  @hpa = nil             # Limpiar gráfico HPA*
  @reachable_set = nil   # Limpiar conjunto reachable
end

# Llamado cuando:
# - Evento cierra puerta (switch flip)
# - Mapa cambia
# - Surfing/Diving inicia/termina
```

## Configuración de Usuario

```ruby
# core/foundation/config.rb
[:route_reach,         128,   :reach, :pathfinder_adv, :lbl_reach,      :help_reach],
# Distancia máxima a considerar (diamond radius)

[:astar_max,           2500,  :astar, :pathfinder_adv, :lbl_astar,      :help_astar],
# Máximo de nodos a explorar (tope por nodos, usado cuando route_auto está apagado)

[:route_auto,          false, :flag,  :debug, :lbl_route_auto,  :help_route_auto],
# Esfuerzo automático: en vez de cortar por nodos (astar_max), corta por TIEMPO (route_budget_ms).
# Garantiza un frame estable en mapas grandes; el alcance encontrado se adapta al PC. Vive en el menú de
# Depuración (no en pathfinder avanzado): puede cortar una ruta larga real antes de hallarla, así que por
# defecto está apagado para conservar el alcance máximo.

[:route_budget_ms,     8,     :ms,    :debug, :lbl_route_budget, :help_route_budget],
# Tiempo máximo (ms) de una búsqueda cuando route_auto está activo. El reloj se comprueba cada
# 256 nodos (Pathfinder::BUDGET_CHECK) para no pagar la llamada al reloj en cada iteración.

[:path_algorithm,      :astar, :algo,  :pathfinder_adv, :lbl_path_algorithm, :help_path_algorithm],
# :astar, :jps (Jump Point Search), :hpa (Hierarchical)

[:edge_relax,          false, :flag,  :pathfinder_adv, :lbl_edge_relax,  :help_edge_relax],
# Relajación de bordes (permite rutas no óptimas pero más rápidas)

[:ledge_directions,    true,  :flag,  :pathfinder_adv, :lbl_ledge_dir,   :help_ledge_dir],
# Respetar dirección de ledges (true = one-way, false = ignorar)

[:route_cache,         true,  :flag,  :pathfinder_adv, :lbl_route_cache, :help_route_cache],
# Cachear passability (mucho más rápido pero menos responsive a cambios)
```

## Uso en Práctica

### Trazar ruta a un tile

`find_path` toma el tile DESTINO (parte siempre de la posición del jugador) y devuelve la lista de
pasos, o `nil` si no hay ruta:

```ruby
path = PokeAccess::Pathfinder.find_path(target_x, target_y)
if path.nil?
  PokeAccess.speak("Sin ruta", true)
end
```

El Locator es quien orquesta la navegación a objetos: `select_current` fija el objetivo enfocado y
activa la guía; la guía por frame (el chime direccional) vive en `core/nav/guide.rb`, no en un
`$game_variable`. El flujo de usuario es rebuild_targets → step/cycle_category → select_current.

### Cadencia del chime de guía (evitar el "galope")

El chime de guía suena cada `guide_interval(dist)` (`guide.rb`): parte de `guide_freq` y **se espacia con la
distancia** (mismo intervalo sobre el objetivo, hasta 2x a `GUIDE_FALLOFF_TILES` o más lejos), para que un
objetivo lejano no machaque el oído. Tres salvaguardas más viven en `guide_tick`:

- **Objetivo sin ruta**: `find_path` devuelve `nil`, pero el chime sigue sonando en línea recta hacia el
  objetivo (`noroute_cue`) para acercarte lo máximo; ese resultado "no hay ruta" se memoiza por
  `[posición, objetivo]` (`@noroute_key`), así NO se re-ejecuta el A* completo cada frame. Se descarta al
  moverte, cambiar de objetivo, o cuando un evento termina (un interruptor que abre paso →
  `Locator.forget_noroute` junto a `invalidate_cache`).
- **Esquinas**: al girar, el jugador está a mitad de paso con `path[0]` apuntando un instante a la pared del
  giro; el recálculo forzado de "siguiente paso bloqueado" se throttlea (`RECHECK_BLOCKED_SEC`) para no
  correr un doble A* por frame en cada esquina (era lo que aceleraba el sonido de pasos del propio juego).
- La precisión de la ruta no se ve afectada: el refresh normal por tick y el rescan de `follow_cached_path`
  siguen corrigiendo obstáculos reales.

### Diagnóstico

```ruby
# Ctrl+Alt+F9 → accessibility/diag.txt
pathfinder: reach=128 algo=:astar max_nodes=2500 cache=true
  last_path_tiles=127
  hpa_clusters=42
  reachable_from_player=892
# Con route_auto activo, max_nodes deja de ser el corte efectivo: la búsqueda para
# por tiempo (route_budget_ms) y devuelve la mejor ruta encontrada en ese plazo.
```

## Rendimiento Esperado

| Configuración | Tamaño Mapa | Tiempo Path | Nota |
|---|---|---|---|
| A* sin caché | 50x50 | 5-15ms | Lento si se repite |
| A* con caché | 50x50 | <1ms | Rápido 2do intento |
| HPA* | 100x100 | 2-5ms | Para mapas grandes |
| Flood | Cualquiera | 10-50ms | Para determinar reachability |

### Corte por nodos vs por tiempo (route_auto)

Por defecto la búsqueda corta por **número de nodos** (`astar_max`): "explora hasta N casillas y para". En un mapa
muy grande o con `passable?` lento eso puede convertirse en un pico de varios frames.

Con **`route_auto` activado** corta por **tiempo** (`route_budget_ms`, 8 ms por defecto): fija una hora límite al
empezar y, comprobando el reloj cada `BUDGET_CHECK` (256) nodos, para en cuanto se supera —devolviendo la mejor
ruta encontrada hasta ahí. El tiempo es constante; lo que varía es cuán lejos llega (más en un PC rápido, menos en
uno lento). El mismo corte temporal se aplica a A*, JPS, al A* sobre el grafo abstracto de HPA* y al flood de
alcanzables (`reachable_tiles`). `astar_max` y `route_reach` siguen siendo topes duros, pero en modo tiempo casi
siempre corta antes el reloj. El A* LOCAL que refina cada portal de HPA* (`hpa_low`) no se limita por tiempo: es
acotado por cluster (10×10) y barato, y el corte temporal del grafo abstracto que lo invoca ya acota el total.

## Referencias

- [Pathfinder Module](core/nav/pathfinder.rb)
- [Locator Naming](core/nav/locator_naming.rb) - Usa pathfinder
- [Guide & Navigation](core/nav/guide.rb) - Auto-walk

## Próximo

- [Audio3D](07_AUDIO3D.md) - Sonido posicional
- [Ruby Fundamentals](08_RUBY_FUNDAMENTALS.md) - Conceptos de Ruby
