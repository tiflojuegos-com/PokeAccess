# PokeEssentialsAccess - Documentación Completa

## Introducción General

**PokeEssentialsAccess** es un toolkit de accesibilidad exhaustivo para fangames de Pokémon construidos sobre **RPG Maker** (específicamente versiones que usan **Pokemon Essentials**). El proyecto inyecta código Ruby a través de **MKXP-Z** (una versión mejorada del motor RPG Maker multiplataforma), permitiendo que juegos que funcionan sobre Essentials tengan soporte completo de:

- 📢 **Lector de pantalla integrado**: Síntesis de voz en tiempo real
- 🗺️ **Buscador de rutas**: Navegación assistida mediante A* y HPA*
- 🔍 **Detector de objetos**: Identificación automática de elementos interactivos en el mapa
- 🎵 **Audio 3D binaural**: Navegación por sonido posicional (Steam Audio HRTF)
- 🎮 **Remapeo de controles**: Teclado accesible para todas las acciones
- 🎪 **Accesibilidad de menús**: Lectura automática de pantallas y opciones
- ⚔️ **Combate accesible**: Descripción de batallas y opciones claras

### ¿Qué es MKXP-Z?

**MKXP-Z** es un intérprete de **RGSS** (Ruby Game Scripting System) de código abierto, multiplataforma, que funciona en Windows, Linux y macOS. Es un fork mejorado de MKXP (el original, que a su vez es un intérprete RGSS). 

MKXP-Z implementa la API de Ruby / RGSS que RPG Maker XP esperaba, permitiendo ejecutar juegos de RPG Maker en cualquier plataforma sin depender de Windows ni de DirectX. Es particularmente importante porque:

1. **Ejecuta Pokemon Essentials**: El proyecto original de MKXP-Z fue hacer correr Pokémon Essentials en múltiples plataformas
2. **Soporta preload scripts**: Permite inyectar código Ruby *antes* de que carguen los scripts del juego
3. **Win32API completa**: Acceso a APIs de Windows desde Ruby (necesario para audio, clipboard, etc.)

### ¿Qué es Pokemon Essentials?

**Pokemon Essentials** es un framework RPG Maker completo que facilita la creación de fangames de Pokémon. Proporciona:

- Sistema de batalla completo tipo Pokémon
- Gestión de Pokédex, mochilas, equipo
- Movimientos y habilidades
- Elementos del mundo Pokémon (gimnasios, NPCs, etc.)

Existe en varias versiones:
- **Gen-6 (v16-v17)**: Versión antigua, usa clases nombradas como `PokeBattle_Scene`, `PB*`
- **Era GameData (v19+)**: Usa `GameData::*` para acceso a datos
- **v21**: Versión v19-v21.1 con muchas mejoras
- **v22**: Gran refactor UI con clases `UI::*`
- **Sky**: Fork especial que backportea v22 UI a v21

### Estructura del Proyecto

```
PokeEssentialsAccess/
├── core/                    # Núcleo compartido (Engine-agnostic)
├── games/<name>/            # Capa específica por juego
├── loader/                  # Sistema de carga
├── lang/                    # Traducciones i18n
├── assets/                  # Sonidos y voces
├── installer/               # Instalador/desinstalador
├── native/                  # DLLs para audio 3D (PA3D_steam.dll)
└── test/                    # Herramientas de testing
```

## Conceptos Clave

### 1. **Inyección de Código (Code Injection)**

El proyecto NO modifica directamente los juegos. En su lugar:

1. Los archivos de PokeEssentialsAccess se colocan en una carpeta `accessibility/`
2. Se carga un **preload script** a través de `mkxp.json`
3. El preload espera a que el juego esté listo (cuando `$scene` está definido)
4. Luego eval()'s el archivo `boot.rb` que inicializa todo

Esta aproximación significa:
- El juego original NO se modifica
- PokeEssentialsAccess es completamente removible
- Funciona con cualquier versión de Essentials (gen-6 o era GameData)

### 2. **Ruby: eval() y Monkey Patching**

Ruby permite modificar clases en tiempo de ejecución usando `eval()` (evaluación de código como strings):

```ruby
# En lugar de editar la clase:
class GameClass
  def method_name
    original_logic
  end
end

# Se puede hacer:
eval(File.read("patch_file.rb"))  # Que contiene métodos adicionales

# O parchear métodos existentes con alias_method:
original = GameClass.instance_method(:method_name)
GameClass.define_method(:method_name) do
  # Lógica nueva
  original.bind(self).call
end
```

### 3. **Versiones de Essentials**

El proyecto necesita detectar qué versión de Essentials se ejecuta porque:
- **Gen-6** usa clases `PokeBattle_Scene`, datos en tablas `PB*`
- **Era GameData** usa `GameData::*`, `Battle::Scene`
- **v22** cambió completamente a `UI::*`

Solución: Detección en tiempo de ejecución + manifests modulares

### 4. **Manifests y Carga Ordenada**

En lugar de un glob desordenado (`require_all 'modules/*'`), cada carpeta tiene `manifest.rb`:

```ruby
# core/manifest.rb
%w[
  foundation/config
  foundation/engine
  foundation/events
  # ... más módulos en orden de dependencia
]
```

Esto asegura que las dependencias se cargan primero.

## Flujo de Carga

```
MKXP-Z inicia
  ↓
Ejecuta preload script (loader/preload_access.rb)
  ↓
Espera a que el juego esté listo (Graphics.update hook)
  ↓
Eval boot.rb (loader/boot.rb)
  ↓
PokeAccessBoot.run
  ├─ Carga core/ (por manifest)
  │  ├─ foundation/ (config, engine, eventos, etc.)
  │  ├─ data/ (providers de datos)
  │  ├─ speech/ (síntesis de voz)
  │  └─ ... (nav, audio, menus, batalla, etc.)
  │
  ├─ Carga game/<nombre>/ (por manifest)
  │  └─ Constantes y pantallas específicas del juego
  │
  └─ Aplica PokeAccess::Settings (user overrides)
```

## Arquitecura de Capas

```
┌─────────────────────────────────────────┐
│      Juego Específico (games/<name>)    │  ← Constantes por juego, UI específica
├─────────────────────────────────────────┤
│      Motor Específico (core/*/v21/, v22/) │  ← Adaptadores para Battle::Scene, UI::*
├─────────────────────────────────────────┤
│      Core Compartido (core/*/*)         │  ← Lógica universal
├─────────────────────────────────────────┤
│      Pokemon Essentials + MKXP-Z        │  ← Base del juego
└─────────────────────────────────────────┘
```

## Siguiente: Leer otros documentos

- [Arquitectura](02_ARCHITECTURE.md) - Detalles de cada capa
- [Sistemas Core](02_CORE_SYSTEMS.md) - Componentes principales
- [Detección de Engine](03_ENGINE_DETECTION.md) - Cómo detecta versiones
- [API de Datos](05_DATA_API.md) - Cómo accede a datos de Pokémon
- [Audio 3D](07_AUDIO3D.md) - Sistema de navegación por sonido
- [Pathfinding](06_PATHFINDING.md) - Búsqueda de rutas
