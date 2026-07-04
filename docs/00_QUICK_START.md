# Quick Start - Resumen en 5 Minutos

¿Prisa? Aquí está todo lo que necesitas saber en 5 minutos.

## ¿Qué es PokeEssentialsAccess?

Toolkit de accesibilidad que añade:
- 📢 Síntesis de voz (lector de pantalla)
- 🗺️ Búsqueda automática de rutas
- 🎵 Audio 3D posicional
- 🎮 Controles accesibles
- ⚙️ Configuración extensible

Para juegos Pokémon basados en **RPG Maker**.

## ¿Cómo Funciona?

```
1. MKXP-Z (motor del juego) carga el juego
2. PokeAccess se inyecta automáticamente
3. Engancha métodos de Essentials SIN modificarlos
4. Añade funcionalidad accesible
5. Todo sucede en runtime (en memoria)
```

**Clave**: Nada es modificado permanentemente. Es como un plugin.

## Estructura en 30 Segundos

```
PokeEssentialsAccess/
├── core/           ← Código compartido por TODOS los juegos
├── games/<game>/   ← Personalización por juego
├── loader/         ← Cómo se carga todo
├── native/         ← DLL para audio 3D
└── docs/           ← Documentación (tú estás aquí)
```

## 3 Puntos Clave

### 1️⃣ Múltiples Versiones de Essentials

```
Gen-6 (v16-v17):  PBSpecies.getName(123)
Era GameData (v19+):   GameData::Species.get(123).name

PokeAccess soporta AMBAS automáticamente
```

### 2️⃣ Enganches (Hooks)

```ruby
# En lugar de modificar:
class PokeBattle_Scene
  def pbDisplayMessage(msg)
    # código original
  end
end

# PokeAccess hace:
PokeAccess::Hooks.before_hook("PokeBattle_Scene", :pbDisplayMessage) { |s, args|
  PokeAccess.speak(args[0])
}
```

### 3️⃣ Providers de Datos

```
Un método funciona en TODAS las versiones:
PokeAccess::Data.species_name(123)  # "Pikachu"
  ↓
  ├─ Si gen-6: llama PBSpecies.getName(123)
  ├─ Si usa GameData: llama GameData::Species.get(123).name
  └─ Si desconocido: devuelve el id crudo "123"
```

## Así se Carga

```
MKXP-Z comienza
  ↓
Espera a que juego esté listo (Graphics.update)
  ↓
Carga boot.rb
  ├─ Carga core/ (foundation, data, speech, audio, etc.)
  ├─ Carga games/<nombre>/ (personalización)
  └─ Aplica settings de usuario
  ↓
¡PokeAccess completamente funcional!
```

## Métodos Más Usados

```ruby
# Hablar
PokeAccess.speak("Hola")

# Datos (funciona en cualquier versión)
PokeAccess::Data.species_name(25)      # "Pikachu"

# Versión actual
PokeAccess::Engine.gamedata?             # true o false
PokeAccess::Engine.version             # 21.1

# Ruta hacia un tile (desde la posición del jugador)
path = PokeAccess::Pathfinder.find_path(10, 10)

# Configuración
PokeAccess::Config.audio3d_volume = 80

# Buscar cercanos (reconstruye la lista y anuncia el seleccionado)
PokeAccess::Locator.rebuild_targets
PokeAccess::Locator.announce_selected(true)   # true = incluir el nombre
```

## Ruby: Conceptos Mínimos

```ruby
# Módulo (como clase, pero sin instancias)
module MiModulo
  def self.mi_metodo
    "resultado"
  end
end
MiModulo.mi_metodo  # → "resultado"

# Bloque ({ código })
[1,2,3].each { |x| puts x }  # Imprime 1, 2, 3

# Símbolo (:nombre)
{ :idioma => :es, :audio => true }

# Hash (diccionario)
config = { :volumen => 80 }
config[:volumen]  # → 80
```

## Dónde Está Todo

| Qué | Dónde |
|-----|-------|
| Configuración | `core/foundation/config.rb` |
| Detección engine | `core/foundation/engine.rb` |
| Datos (agnóstico) | `core/data/data.rb` |
| Gen-6 específico | `core/battle/gen6/`, `core/data/gen6/` |
| Específico era GameData | `core/battle/v21/`, `core/data/v21/` |
| Audio 3D | `core/audio/audio3d.rb` |
| Rutas | `core/nav/pathfinder.rb` |
| Síntesis voz | `core/speech/speech.rb` |
| Personalizaciones | `games/<nombre>/` |

## Diagnóstico Rápido

Si algo falla:

```bash
# 1. Ver errores
$ cat accessibility/data/loader_error.txt

# 2. Ver si preload funcionó
$ cat accessibility/data/preload_started.txt

# 3. Generar diagnóstico (Ctrl+Alt+F9 en juego)
$ cat accessibility/data/diag.txt
```

## Contribuir: Pasos

1. Entender [Introducción](01_INTRODUCTION.md) (10 min)
2. Entender [Arquitectura](02_ARCHITECTURE.md) (20 min)
3. Leer código relevante en `core/`
4. Hacer cambio/fix
5. Testear

## Documentación Completa

- **[INDEX](12_INDEX.md)** - Mapa de todos los documentos
- **[READING_GUIDE](13_READING_GUIDE.md)** - Ruta personalizada según tu rol
- **[Introducción](01_INTRODUCTION.md)** - Explicación profunda
- **[Arquitectura](02_ARCHITECTURE.md)** - Cómo todo se conecta
- **[Engine Detection](03_ENGINE_DETECTION.md)** - Múltiples versiones
- **[Patching & Hooks](04_PATCHING_AND_HOOKS.md)** - Cómo se engancha
- **[Data API](05_DATA_API.md)** - Acceso agnóstico a datos
- **[Pathfinding](06_PATHFINDING.md)** - Búsqueda de rutas
- **[Audio3D](07_AUDIO3D.md)** - Sonido 3D
- **[Loading System](09_LOADING_SYSTEM.md)** - Proceso de carga
- **[API Reference](10_API_REFERENCE.md)** - Quick lookup
- **[Dependencies](11_DEPENDENCIES_TREE.md)** - Qué depende de qué

## En 30 Segundos: ¿Por qué es diferente?

### ❌ Alternativa tradicional (modificar archivos):
```
Essentials original: 100 archivos .rb
Parchear manualmente cada uno
Resultado: Código desordenado, mantenimiento imposible
```

### ✅ Solución PokeEssentialsAccess (enganches):
```
Essentials original: Sin modificar
+ PokeAccess carga en runtime
+ Usa hooks para interceptar métodos
= Funcionalidad nueva sin tocar original
```

## Próximos Pasos

- **Primero vez**: Lee [Introducción](01_INTRODUCTION.md)
- **Necesitas referencia**: Ve a [API Reference](10_API_REFERENCE.md)
- **Eres contributor**: Sigue [READING_GUIDE](13_READING_GUIDE.md)
- **Tienes problema**: Ve a [Dependencies](11_DEPENDENCIES_TREE.md)

---

**¿Preguntas?** Consulta [Índice](12_INDEX.md)

Versión: 1.0  
Última actualización: 2026-06-22
