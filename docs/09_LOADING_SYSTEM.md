# Sistema de Carga - Boot Process

## Flujo General de Carga

```
┌─────────────────────────────────────────┐
│ MKXP-Z inicia el juego                  │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ Lee mkxp.json (configuración)           │
│  - busca "preloadScript"                │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ Carga preload scripts (Ruby)            │
│ loader/preload_access.rb ejecuta        │
│  - Envuelve Graphics.update             │
│  - Marca "preload_started.txt"          │
│  - Espera señal para eval boot.rb       │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ Carga Scripts.rxdata (scripts del juego)│
│ Essentials y todos los scripts          │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ Main loop inicia                        │
│  - Graphics.update se llama cada frame  │
│  - Nuestro hook detecta: ¿Listo?       │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ Primera frame: eval boot.rb             │
│ loader/boot.rb ejecuta                  │
│  - Carga core/ por manifest             │
│  - Carga games/<game>/ por manifest     │
│  - Aplica settings de usuario           │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ Juego completamente funcional con       │
│ PokeEssentialsAccess totalmente integrado│
└─────────────────────────────────────────┘
```

## Etapa 1: Preload Script

**Ubicación**: `loader/preload_access.rb`

Este script se ejecuta **ANTES** de que Essentials cargue (por eso se llama "preload"):

```ruby
module AccessPreload
  PATH = "accessibility/boot.rb"
  @loaded = false
  @frames = 0
  READY_FRAME = 120
  
  def self.mark_started
    # Escribir marcador: preload ejecutó correctamente
    File.open("accessibility/data/preload_started.txt", "w") { |f|
      f.write("preload ok ruby=#{RUBY_VERSION}\n")
    }
  rescue StandardError
  end
  
  def self.try_load
    return if @loaded
    @frames += 1
    
    # Señal 1: ¿$scene fue definido? (usuario en el juego)
    # Señal 2: ¿Pasaron 120 frames? (timeout safety)
    return unless (defined?($scene) && $scene) || @frames >= READY_FRAME
    
    @loaded = true
    eval(File.read(PATH), TOPLEVEL_BINDING, PATH)
  end
  
  class << Graphics
    alias_method :update__access_preload, :update
    def update(*a)
      r = update__access_preload(*a)
      AccessPreload.try_load
      r
    end
  end
end

AccessPreload.mark_started
```

**¿Cómo funciona?**

1. Envuelve `Graphics.update` con un alias
2. Cada frame: llamar `update__access_preload` (original)
3. Luego: comprobar si el juego está listo
4. Si listo: eval boot.rb una sola vez
5. De ahora en adelante: solo llamar update original

**Ruby Trick: alias_method**
```ruby
# Guardar referencia al original
alias_method :update__access_preload, :update

# Redefinir update
def update(*a)
  # Código personalizado aquí
  update__access_preload(*a)  # Llamar al original
end
```

## Etapa 2: Boot (Carga Principal)

**Ubicación**: `loader/boot.rb`

```ruby
module PokeAccessBoot
  ROOT = "accessibility"
  
  def self.run
    # 1. Cargar core (núcleo)
    load_manifest("#{ROOT}/core")
    
    # 2. Cargar juego específico
    load_manifest("#{ROOT}/game")
    
    # 3. Aplicar settings de usuario
    (PokeAccess::Settings.apply rescue nil) if defined?(PokeAccess) && PokeAccess.const_defined?(:Settings)
    
    # 4. Diagnóstico: ¿hooks faltantes?
    miss = (PokeAccess::Hooks.missing rescue [])
    log("[diag] enganches sin metodo: #{miss.join(', ')}") if miss && !miss.empty?
    
    # 5. Diagnóstico: ¿provider de datos?
    if defined?(PokeAccess::Data) && (PokeAccess::Data.active_priority rescue nil).to_i <= 0
      log("[diag] PokeAccess::Data en modo emergencia: ID crudos")
    end
    
    # 6. Diagnóstico: ¿i18n sin paridad? (clave en un idioma y no en otro)
    par = (PokeAccess::I18n.parity_issues rescue [])
    log("[diag] i18n sin paridad: #{par.join(', ')}") if par && !par.empty?
  end
  
  def self.load_manifest(dir)
    mf = "#{dir}/manifest.rb"
    unless File.exist?(mf)
      log("#{dir}: sin manifest.rb")
      return
    end
    
    # Leer manifest (array de rutas)
    list = (eval(File.read(mf), TOPLEVEL_BINDING, mf) rescue nil)
    unless list.is_a?(Array)
      log("#{mf}: no devolvio array")
      return
    end
    
    # Cargar cada módulo en orden
    list.each { |entry| load_module("#{dir}/#{entry}.rb") }
  end
  
  def self.load_module(path)
    eval(File.read(path), TOPLEVEL_BINDING, path)
  rescue Exception => e
    raise if e.is_a?(SystemExit)
    log("#{path}: #{e.class}: #{e.message}\n#{(e.backtrace || []).join("\n")}")
  end
  
  def self.log(msg)
    # Escribir a archivo de log
    dir = (defined?(PokeAccess::Paths) && PokeAccess::Paths.const_defined?(:DATA)) ? 
          PokeAccess::Paths::DATA : "#{ROOT}/data"
    File.open("#{dir}/loader_error.txt", "a") { |fh| fh.write("#{msg}\n\n") }
  rescue StandardError
  end
end

PokeAccessBoot.run
```

## Manifests: Orden de Carga

### Core Manifest

**Ubicación**: `core/manifest.rb`

```ruby
%w[
  # Foundation PRIMERO (todo depende)
  foundation/config
  foundation/const      # const_at: resolución de "A::B::C" 1.8.7-safe (todo depende)
  foundation/paths
  foundation/i18n
  util/grouping         # helpers puros (union_groups) - sin dependencias
  util/text             # helpers puros (join_parts, types_phrase)
  util/player
  foundation/game
  foundation/engine
  foundation/world
  foundation/settings
  foundation/events
  foundation/caches
  foundation/clipboard
  foundation/perf
  foundation/tags
  foundation/map_names  # nombres de mapa personalizados (depende de Paths)

  # Data (readers agnósticos)
  data/data
  data/data_fallback
  data/gen6/data_g6
  data/v21/data_v21

  # Speech (depende de Paths)
  speech/markers
  speech/text
  speech/speech

  # Input (depende de Engine, Settings)
  input/hooks
  input/remap
  input/input

  # Menus, Navigation, Audio
  menus/config_menu
  nav/terrain
  audio/spatial
  audio/audio3d

  # Battle (readers agnósticos + subcarpetas por motor gated por clase)
  battle/battle
  battle/gen6/battle_g6
  battle/v21/battle_v21
  battle/v22/battle_v22

  # ... más módulos (ver core/manifest.rb para la lista completa)
]
```

El manifest real define cuatro niveles de subcarpeta por subsistema, cada uno gated por
existencia de clase para que sea no-op fuera de su motor: `<módulo>/gen6/` (Ruby 1.8.7:
`PokeBattle_Scene`, `PScreen`, datos `PB*`), `<módulo>/v21/` (era GameData, Essentials v19-v21.1),
`<módulo>/v22/` (rework `UI::`) y `<módulo>/skyflyer/` (clases del fork de La Base de Sky y sus
plugins, p.ej. DBK o el tutor de movimientos huevo, ausentes en Essentials vanilla).

**Orden es CRÍTICO:**
- `foundation/engine` debe cargar ANTES de `data/gen6/` (necesita Engine.kind)
- `data/data` debe cargar ANTES de `data/gen6/` (necesita Data module)
- `speech/markers` debe cargar ANTES de `speech/speech` (depende de write_marker)

### Game Manifest

**Ubicación**: `games/<nombre>/manifest.rb`

```ruby
# games/royal/manifest.rb
%w[
  constants       # Definir PokeAccess::Game
  selectors       # Menus específicos
  currydex
  curry_select
  # ...
]
```

Solo módulos específicos del juego (el core ya se cargó).

## Archivos de Configuración

### mkxp.json (Configuración de MKXP-Z)

```json
{
  "preloadScript": ["accessibility/preload_access.rb"]
}
```

`preloadScript` en mkxp-z es un **array** de scripts (no una cadena suelta). El instalador
(`installer/install.ps1`) inserta `"accessibility/preload_access.rb"` en ese array: si ya existe
uno, añade la entrada; si no, crea la clave. Ese es el único cambio que hace en el `mkxp.json` del
juego; el resto de claves (RTP, soundfont, etc.) son del propio juego y el mod no las toca.

**Nota**: el preload es `preload_access.rb`, NO `boot.rb`. boot.rb no puede ser el preloadScript porque
corre antes de que existan las clases del juego; preload_access.rb difiere la carga (envuelve
Graphics.update y eval-úa boot.rb cuando el juego está listo).

### accessibility/data/loader_error.txt

Errores durante carga:

```
foundation/config: ... error message
data/gen6/data_g6: ... error message
[diag] PokeAccess::Data en modo emergencia: ID crudos
```

### accessibility/data/preload_started.txt

Marcador de que preload ejecutó (para diagnóstico):

```
preload ok ruby=1.8.7
```

## Ruby: eval() con TOPLEVEL_BINDING

**¿Qué es eval()?**

```ruby
# eval ejecuta código Ruby como string en tiempo de ejecución
code = 'x = 5; puts x'
eval(code)  # OUTPUT: 5
```

**¿Qué es TOPLEVEL_BINDING?**

```ruby
# Binding = contexto de variables
# TOPLEVEL_BINDING = contexto global

module PokeAccess
  X = 42
end

eval("puts PokeAccess::X", TOPLEVEL_BINDING)  # Accede a PokeAccess

# Sin TOPLEVEL_BINDING, usa contexto local (no ve PokeAccess)
```

**¿Por qué es seguro?**

- Los archivos son DE CONFIANZA (vienen con PokeEssentialsAccess, no de usuario)
- Se cargan DESPUÉS de Essentials (ya todo inicializado)
- Igual a cómo RMXP carga Scripts.rxdata

> **Resolución de clases 1.8.7-safe**: durante y tras la carga, el código nunca llama `Object.const_defined?`
> sobre un nombre con `"::"` (en Ruby 1.8.7, el de gen-6, eso lanza un error). Todo pasa por
> `PokeAccess.const_at("A::B::C")` (`core/foundation/const.rb`), que recorre los segmentos uno a uno. Lo
> usan `Hooks`, el escaneo de `Input`, `Menus` y `Engine.has?`, así que un nombre de clase anidado nunca
> rompe el loader de gen-6.

## Orden de Dependencias Visual

```
foundation/config
foundation/engine
    ↑ (depende)
    
data/data.rb
    ↑
data/data_fallback.rb
data/gen6/data_g6.rb  ← Registra provider gen-6
data/v21/data_v21.rb  ← Registra provider de la era GameData
    
speech/markers.rb
    ↑
speech/text.rb
speech/speech.rb      ← Usa SRAL.dll
    
input/hooks.rb        ← Semi-API de hooks (before/after/around/frame/wrap_*)
    ↑ (depende de Engine, Settings)
input/remap.rb
input/input.rb
    
menus/menus.rb
    ↑ (depende de Data, Engine, Speech)
menus/neo_pausemenu.rb
    
audio/spatial.rb
    ↑
audio/audio3d.rb      ← Inicializa PA3D_steam.dll
    
battle/battle.rb      ← Lógica compartida
    ↑
battle/gen6/battle_g6.rb  ← Hooks si gen-6
battle/v21/battle_v21.rb  ← Hooks si era GameData
```

## Recuperación de Errores

### Try-Rescue en Boot

```ruby
def self.load_module(path)
  eval(File.read(path), TOPLEVEL_BINDING, path)
rescue Exception => e
  raise if e.is_a?(SystemExit)  # No silenciar salidas
  log("Error en #{path}:")
  log("#{e.class}: #{e.message}")
  log("#{(e.backtrace || []).join("\n")}")
end

# Resultado:
# - Error no detiene el juego
# - Se registra en loader_error.txt
# - Módulos posteriores se cargan de todas formas
# - Si es crítico, fallos en cascada aparecen rápido
```

### Fallback para Paths

```ruby
def self.log(msg)
  # Intenta usar PokeAccess::Paths si existe
  dir = (defined?(PokeAccess::Paths) && PokeAccess::Paths.const_defined?(:DATA)) ? 
        PokeAccess::Paths::DATA : "accessibility/data"
  
  File.open("#{dir}/loader_error.txt", "a") { |fh| fh.write("#{msg}\n\n") }
rescue StandardError
  # Si falla escribir: silenciosamente ignorar (el juego debe continuar)
end
```

## Diagnóstico: Entender la Carga

### Ver errores

```bash
$ cat accessibility/data/loader_error.txt
```

### Ver qué se cargó

```ruby
# Agregar al final de boot.rb:
p "PokeAccess::Config = #{PokeAccess::Config}"
p "PokeAccess::Data.active = #{PokeAccess::Data.active}"
p "PokeAccess::Engine.version = #{PokeAccess::Engine.version}"
```

### Validar preload

```bash
# ¿Preload ejecutó?
$ cat accessibility/data/preload_started.txt
preload ok ruby=1.8.7
```

## Referencias

- [Boot Script](loader/boot.rb)
- [Preload Script](loader/preload_access.rb)
- [Native Loader](loader/Loader.rb) - Para RMXP sin MKXP-Z
- [Core Manifest](core/manifest.rb)

## Próximo

- [Dependencies Tree](11_DEPENDENCIES_TREE.md) - Árbol completo
- [Ruby Fundamentals](08_RUBY_FUNDAMENTALS.md) - Conceptos necesarios
