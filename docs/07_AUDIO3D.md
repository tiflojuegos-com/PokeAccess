# Audio3D - Navegación por Sonido Posicional

## Concepto: HRTF Binaural Audio

**Audio 3D Binaural** es reproducción de sonido que parece venir de un punto específico en el espacio 3D alrededor del jugador. Funciona porque:

1. Humanos localizan sonido por diferencias de **tiempo** y **volumen** entre oídos
2. HRTF (Head-Related Transfer Function) simula cómo ondas sonoras se modifican al llegar a orejas
3. Al reproducir con HRTF correcto, el cerebro percibe dirección del sonido

**Ejemplo**:
```
┌────────────────────────┐
│        Jugador         │
│    (con headphones)    │
├────────────────────────┤
│  Oído izq    Oído der  │
└────────────────────────┘
    ↑            ↑
    │            └──── NPC a la DERECHA
    │                  Audio panned derecha (volumen ↑ oído der)
    └─────────────────── NPC a la IZQUIERDA
                         Audio panned izquierda (volumen ↑ oído izq)
```

## Steam Audio y PA3D_steam.dll

**Steam Audio** es librería de audio 3D de Valve que proporciona:
- HRTF binaural
- Oclusión de sonido (sonido muere al atravesar paredes)
- Efectos ambientes

**PA3D_steam.dll** es wrapper Win32 que expone Steam Audio a Ruby:

```
Ruby código
  ├─ Llama Win32API
  └─ PA3D_steam.dll
     ├─ Carga Steam Audio (Phonon library)
     ├─ Posiciona canales de audio
     ├─ Aplica HRTF
     └─ Devuelve result a Ruby
```

## Arquitectura de Audio3D

**Ubicación**: `core/audio/audio3d.rb`

### Inicialización

```ruby
module PokeAccess::Audio3D
  DLL = "PA3D_steam.dll"

  # DLL functions via Win32API (cada una rescatada: si la dll falta, queda nil y available? lo detecta)
  INIT = (Win32API.new(DLL, "PA3D_Init",     [],                        "i") rescue nil)
  CHAN = (Win32API.new(DLL, "PA3D_Channel",  ["p", "i"],                "i") rescue nil)
  LIS  = (Win32API.new(DLL, "PA3D_Listener", ["i", "i"],                "v") rescue nil)
  SET  = (Win32API.new(DLL, "PA3D_Set",      ["i", "i", "i", "i", "i"], "v") rescue nil)
  MAST = (Win32API.new(DLL, "PA3D_Master",   ["i"],                     "v") rescue nil)
  RATE_FN = (Win32API.new(DLL, "PA3D_Rate",    [], "i") rescue nil)   # tasa nativa del dispositivo
  LAT_FN  = (Win32API.new(DLL, "PA3D_Latency", [], "i") rescue nil)   # latencia de salida (ms)
  OCCL = (Win32API.new(DLL, "PA3D_Occl", ["i", "i"], "v") rescue nil)
  AIR  = (Win32API.new(DLL, "PA3D_Air",  ["i"],      "v") rescue nil)
  OCCLUDE_AMOUNT = 80   # cuánto se atenúa (0-100) un emisor tras pared en modo :occlude

  # True si la dll está presente y resolvieron sus puntos de entrada (OCCL/AIR/RATE/LAT son opcionales).
  def self.available?; INIT && CHAN && LIS && SET && MAST; end

  def self.boot
    return @ready if @ready
    return false if @boot_tried
    @boot_tried = true
    return false unless available?
    return false unless INIT.call == 1

    @rate    = (RATE_FN.call rescue nil)   # tasa nativa del dispositivo
    @latency = (LAT_FN.call  rescue nil)

    # Carga cada canal desde su .wav (0 = un disparo, 1 = loop). Nombres reales del repo.
    @ch[:npc]        = load_ch("pa3d_npc.wav",        0)
    @ch[:object]     = load_ch("pa3d_object.wav",     0)
    @ch[:door]       = load_ch("pa3d_door.wav",       0)
    @ch[:teleporter] = load_ch("pa3d_teleporter.wav", 0)
    @ch[:hazard]     = load_ch("pa3d_hazard.wav",     0)
    @ch[:wall]       = load_ch("pa3d_wall.wav",       0)
    @ch[:interact]   = load_ch("pa3d_interact.wav",   0)   # choque contra npc/objeto
    @ch[:control]    = load_ch("pa3d_control.wav",    0)
    @ch[:water]      = load_ch("pa3d_water.wav",      1)   # loop
    @ch[:wind_w]     = load_ch("pa3d_wind_w.wav",     1)   # un loop de viento por lado de pared (w/e/n/s)
    @ch[:wind_e]     = load_ch("pa3d_wind_e.wav",     1)
    @ch[:wind_n]     = load_ch("pa3d_wind_n.wav",     1)
    @ch[:wind_s]     = load_ch("pa3d_wind_s.wav",     1)
    @ch[:trap]       = load_ch("pa3d_boop.wav",       0)   # movedores (puzzles con movers)
    @ch[:push]       = load_ch("pa3d_boing.wav",      0)   # baldosas de empuje (categoria :push)
    @ch[:step]       = load_ch("pa_step.wav",         0)
    @ch[:grass]      = load_ch("pa_grass.wav",        0)
    @ch[:fstep_water] = load_ch("pa_water.wav",       0)
    @ch[:guide]      = load_ch("pa_guide_c.wav",      0)
    @ready = true
  rescue StandardError => e
    log3d(:boot, e)
    false
  end

  def self.load_ch(name, loop_flag)
    (CHAN.call("#{wav(name)}\0", loop_flag) rescue -1)
  end
end
```

**¿Por qué `"\0"` al final?**
- C/Win32 espera null-terminated strings
- Ruby String no incluye null terminator automáticamente
- `"\0"` lo añade para que C pueda leerlo correctamente

### Posicionamiento

```ruby
# Las coordenadas de tile se escalan a unidades del motor (TILE_UNITS = 100) y se pasan a la dll.
# OJO: PA3D_Set NO tiene eje Z. Su firma real es (canal, x, y, VOLUMEN, on):
#   - 4º arg = volumen 0-100 (no una altura)
#   - 5º arg = on/off (1 reproduce/posiciona, 0 silencia)
# Es panorámica 2D por HRTF; no hay altura.

# Posicionar un emisor a (tx, ty) tiles con un volumen:
SET.call(channel, tx * TILE_UNITS, ty * TILE_UNITS, vol, 1)

# Listener (oído del jugador): siempre en (0, 0)
# Los emitores se posicionan RELATIVO al listener

# Ejemplo:
# Jugador en (100, 100)
# NPC en (105, 100)
# Offset: (5, 0)
# → Audio panned a la DERECHA
```

## Detectores de Sonido (Emitters)

### Tipos de Emitores

```ruby
module PokeAccess::Audio3D
  PING_DEFS = {
    :npc => :audio3d_freq_npc,        # NPCs
    :object => :audio3d_freq_object,  # Objetos interactivos
    :door => :audio3d_freq_door,      # Puertas
    :hazard => :audio3d_freq_object,  # Peligros
    :trap => :audio3d_freq_object,    # Movedores (puzzles con movers)
    :control => :audio3d_freq_object, # Switches
    :push => :audio3d_freq_object,    # Baldosas de empuje (canal pa3d_boing)
    :teleporter => :audio3d_freq_door # Teleportadores
  }
end
```

### Cadencia (Frequency)

```ruby
# Cada tipo tiene frecuencia configurable
# Por ejemplo, NPC frecuencia 70 = ping cada 70% de tiempo

config.audio3d_freq_npc = 70    # NPCs: suena 70% del tiempo
config.audio3d_freq_object = 70 # Objetos: suena 70% del tiempo
config.audio3d_freq_door = 70   # Puertas: suena 70% del tiempo

# Ej: en 100 updates, NPC suena ~70 veces
```

### Alternancia de Emitores Cercanos

```ruby
NEAR_MAX = 3      # Máximo 3 emisores cercanos por tipo (se guardan los más próximos)
PING_GAP = 0.25   # Ventana (s) tras un ping durante la que se retienen los cercanos

# Problema: Si hay 10 NPCs en una zona pequeña,
# todos sonando simultáneamente = ruido caótico

# Solución:
# 1. Mantener solo los 3 más cercanos de cada tipo (NEAR_MAX)
# 2. Dentro de PING_GAP tras un ping, solo se retienen los candidatos que están
#    a <= alt_dist tiles de ESE ping; uno más lejos SÍ puede sonar (el HRTF ya los separa).
# 3. Dentro de un tipo, ping_types recorre en round-robin sus más cercanos para que alternen.

# alt_dist es configurable (audio3d_alt_dist, por defecto 5 tiles):
def self.alt_dist; (PokeAccess::Config.audio3d_alt_dist rescue 5).to_i; end

@emitters = {}  # { :npc => [[x, y], ...], :object => [...], ... } por tipo, los más cercanos

# El método real por frame es tick (lo llama el hook Game_Player#update). Silencia si sound_nav está
# :off, si Spatial está ocupado (mensaje/menú) o si estás en menú; en modo distinto a :full deja solo
# pasos y choques. En un cambio de tile re-escanea (rescan/walls/winds/water); cada frame pinga los
# emisores discretos por temporizador con ping_types. Cada paso corre aislado en step3d (si uno falla,
# se loguea una vez y los demás siguen).
def self.tick
  return unless boot                                  # no arranca si la dll falta o sound_nav=off
  px = $game_player.x; py = $game_player.y
  LIS.call(px * TILE_UNITS, py * TILE_UNITS)          # listener siempre sobre el jugador
  return silence_emitters unless nav_full?            # modo != :full: solo pasos/choques
  key = [px, py, $game_map.map_id]
  if @scan_pos != key                                 # solo al cambiar de tile (sondear es caro)
    @scan_pos = key
    step3d(:rescan) { rescan(px, py) }
    step3d(:walls)  { update_walls(px, py) }
    step3d(:winds)  { set_winds(px, py) }
    step3d(:water)  { set_loop(:water, @near[:water], type_vol(:water)) }
  end
  step3d(:ping) { ping_types }                        # emite como mucho UN ping por ventana PING_GAP
end
```

**Modos de `sound_nav`**: `:full` activa todo (pings de npc/objeto/puerta, loop de agua, un loop de viento
por pared); `:off` no arranca ni siquiera el motor. En cualquier otro modo el motor sigue vivo pero solo
suenan pasos (`footstep`) y choques (`bump`) — ver `nav_full?`/`nav_off?` en el módulo.

## Oclusión (Paredes)

### Problema: Sonido a Través de Paredes

```
Jugador   Pared    NPC
   J ---[PARED]--- N

Sin oclusión: Escuchas el NPC igual de claro
Con oclusión: Escuchas NPC pero MUCHO más quieto
```

### Modos de Oclusión

```ruby
# core/foundation/config.rb
[:audio3d_occlusion, :occlude, :occ, :audio3d_walls, :lbl_occlusion, :help_occlusion],

# Valores posibles:
:occlude  # Sonido muffled si está detrás de pared
:hear     # Escuchas todo normalmente (ignora paredes)
:hide     # No escuchas si está detrás de pared (omitir)
```

### Cálculo de Oclusión

```ruby
# El modo se lee de Config (:hear / :occlude / :hide).
def self.occlusion_mode; (PokeAccess::Config.audio3d_occlusion rescue :occlude); end

# Antes de que un canal pinge, set_occlusion fija su oclusión con UN raycast (line_clear?) hacia
# el emisor: si está detrás de pared y el modo es :occlude, se atenúa OCCLUDE_AMOUNT; si no, 0.
# (El modo :hide se aplica antes, en rescan: los emisores tras pared ni siquiera entran en la lista.)
def self.set_occlusion(ch, pos)
  return unless OCCL && $game_player
  occ = 0
  occ = OCCLUDE_AMOUNT if occlusion_mode == :occlude &&
                          !line_clear?($game_player.x, $game_player.y, pos[0], pos[1])
  OCCL.call(ch, occ)
rescue StandardError
  nil
end
```

## Envases de Sonido (Rooms/Air)

```ruby
# Sonidos dentro de edificios vs aire abierto suenan diferente

[:audio3d_air, false, :flag, :audio3d_walls, :lbl_pos_air, :help_pos_air],
# ¿Jugador está en aire? (false = probablemente en edificio)

# Si air=false:
# - Sonidos dentro de edificio suenan como si estuvieran dentro
# - El aire absorbe menos frecuencias altas
```

## Mostradores (Desk bypass)

```ruby
# En modo :hide, un mostrador de servicio (enfermera/tienda/PC) seguiría oculto tras el
# mostrador. desk_bypass? lo mantiene audible si está dentro de audio3d_desk_range tiles.

[:audio3d_desk_range, 2, :desk, :audio3d_walls, :lbl_desk_range, :help_desk_range],
# 0 lo desactiva; 1-3 mantiene audible al empleado tras el mostrador dentro de ese rango.

def self.desk_bypass?(ev, d)
  dk = (PokeAccess::Config.audio3d_desk_range rescue 2).to_i
  return false if dk <= 0 || d > dk
  (PokeAccess::Locator.service_desk?(ev) rescue false)
end
```

## Rango de Detección

```ruby
RANGE = 12            # Rango de sonar por defecto (tiles)
WALL_RANGE = 3        # Rango de paredes por defecto (tiles)

# Configurables:
[:audio3d_range, 12, :tiles, :audio3d_adv, :lbl_sonar_range, :help_sonar_range],
# Máximo: 20 tiles, Mínimo: 1 tile

[:audio3d_wall_range, 3, :tiles, :audio3d_walls, :lbl_wall_range, :help_wall_range],
# Máximo: 20, Mínimo: 1
```

## Paso de Pies (Footsteps)

```ruby
# Cuando el jugador se mueve. El método real es footstep(kind, vol): elige el canal por tipo de paso
# (normal / hierba / agua) y lo dispara con SET (no hay PLAY; el 5º arg=1 reproduce).

def self.footstep(kind, vol)
  ch = @ch[kind]            # :step, :grass o :fstep_water
  return unless ch && ch >= 0
  # En el tile del jugador; el 4º arg es VOLUMEN, el 5º (1) lo reproduce.
  SET.call(ch, $game_player.x * TILE_UNITS, $game_player.y * TILE_UNITS, vol.to_i, 1)
end
```

## Sample Rates (Tasas de Muestreo)

```ruby
# PC puede tener device rate 44100Hz o 48000Hz

# Solución: Assets en ambas tasas
SND48 = "accessibility/sounds/48000"  # Para 48000Hz
# "accessibility/sounds/"              # Para 44100Hz (default)

def self.wav(name)
  if @rate == 48000
    p = "#{SND48}/#{name}"
    return p if File.exist?(p)
  end
  "#{DIR}/#{name}"
end

# Impacto: Sin esto, audio podría estar distorsionado
```

## Movimiento Dinámico (Moving Obstacles)

```ruby
# Algunos eventos se mueven mientras el jugador espera
# (Ej: Sharpedo en agua)

MOVER_SECONDS = 1.0  # cadencia para re-leer solo los movedores (segundos)

# El método real es refresh_movers(px, py). tick lo llama en MOVER_SECONDS, solo cuando el puzzle
# actual declara movedores (Puzzles.has_movers?). Re-lee únicamente los eventos tipo :trap cercanos
# y reemplaza sus tiles cacheados, para que el boop los siga mientras el jugador está quieto.
def self.refresh_movers(px, py)
  out = []
  $game_map.events.each_value do |ev|
    next unless type_of(ev) == :trap
    d = (ev.x - px).abs + (ev.y - py).abs
    next if d > range
    out.push([ev.x, ev.y, d, (ev.character_name.to_s rescue "")])
  end
  @emitters[:trap] = cluster(out).sort_by { |e| e[2] }[0, NEAR_MAX].map { |e| [e[0], e[1]] }
end
```

## Configuración Total de Audio 3D

```ruby
# Volumen maestro
[:audio3d_volume, 80, :vol, :audio, :lbl_pos_master, :help_pos_master],

# Volumen por tipo
[:audio3d_npc, 85, :vol, :audio3d_vol, :lbl_pos_people, :help_pos_people],
[:audio3d_object, 85, :vol, :audio3d_vol, :lbl_pos_objects, :help_pos_objects],
[:audio3d_door, 85, :vol, :audio3d_vol, :lbl_pos_doors, :help_pos_doors],
[:audio3d_teleporter, 90, :vol, :audio3d_vol, :lbl_pos_teleporter, :help_pos_teleporter],
[:audio3d_water, 70, :vol, :audio3d_vol, :lbl_pos_water, :help_pos_water],
[:audio3d_wind, 55, :vol, :audio3d_vol, :lbl_pos_wind, :help_pos_wind],
[:footstep_volume, 80, :vol, :audio3d_vol, :lbl_footstep_vol, :help_footstep_vol],
[:wall_volume, 80, :vol, :audio3d_vol, :lbl_wall_vol, :help_wall_vol],
[:event_volume, 70, :vol, :audio3d_vol, :lbl_guide_vol, :help_guide_vol],

# Frecuencia de pings
[:audio3d_freq_npc, 70, :vol, :audio3d_freq, :lbl_freq_people, :help_freq_people],
[:audio3d_freq_object, 70, :vol, :audio3d_freq, :lbl_freq_objects, :help_freq_objects],
[:audio3d_freq_door, 70, :vol, :audio3d_freq, :lbl_freq_doors, :help_freq_doors],
[:guide_freq, 55, :vol, :audio3d_freq, :lbl_guide_freq, :help_guide_freq],

# Oclusión
[:audio3d_occlusion, :occlude, :occ, :audio3d_walls, :lbl_occlusion, :help_occlusion],
[:audio3d_air, false, :flag, :audio3d_walls, :lbl_pos_air, :help_pos_air],
[:audio3d_wall_range, 3, :tiles, :audio3d_walls, :lbl_wall_range, :help_wall_range],
[:audio3d_wall_falloff, 50, :vol, :audio3d_walls, :lbl_wall_falloff, :help_wall_falloff],
[:audio3d_desk_range, 2, :desk, :audio3d_walls, :lbl_desk_range, :help_desk_range],

# Avanzado (rango de sonar y alternancia)
[:audio3d_range, 12, :tiles, :audio3d_adv, :lbl_sonar_range, :help_sonar_range],
[:audio3d_alt_dist, 5, :tiles, :audio3d_adv, :lbl_alt_dist, :help_alt_dist],
```

## Diagnóstico

Los fallos de cada paso del escaneo (rescan, walls, winds, water, ping) y del arranque se escriben en
`accessibility/data/hook_loaded.txt` con `log3d` (deduplicado por paso), p.ej.:

```
audio3d boot: native PA3D dll unavailable (arch mismatch or missing native/)
audio3d rescan: NoMethodError: ... @ ...
```

## Referencias

- [Audio3D Module](core/audio/audio3d.rb)
- [Spatial Module](core/audio/spatial.rb) - Integración con events
- [PA3D_steam.dll](native/_backend.md) - Compilación de DLL

## Próximo

- [Ruby Fundamentals](08_RUBY_FUNDAMENTALS.md)
- [Loading System](09_LOADING_SYSTEM.md)
