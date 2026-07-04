# Índice de Documentación

Bienvenido a la documentación completa de **PokeEssentialsAccess**. Este índice te guiará através de todos los documentos.

## 🚀 Antes de Empezar

### 0. **[Quick Start](00_QUICK_START.md)** - Resumen en 5 minutos
- Lo esencial del mod condensado
- Ideal si tienes prisa antes de leer la introducción completa

## 📚 Documentos Principales

### 1. **[Introducción](01_INTRODUCTION.md)** - COMIENZA AQUÍ
- Qué es PokeEssentialsAccess
- Por qué MKXP-Z es importante
- Estructura general del proyecto
- Conceptos clave
- **Recomendado leer primero**

### 2. **[Arquitectura](02_ARCHITECTURE.md)** - Estructura General
- Capas de la arquitectura (Foundation, Data, Input, Navigation, Battle, etc.)
- Cómo se estructuran los módulos
- Modelo de datos
- Patrones de diseño
- Rendimiento y optimizaciones

### 3. **[Detección de Engine](03_ENGINE_DETECTION.md)** - Múltiples Versiones
- Cómo PokeEssentialsAccess detecta qué versión de Essentials corre
- Diferencias entre Gen-6, era GameData, v22, Sky fork
- Sistema de selección de adaptadores
- Árbol de decisión

### 4. **[Patching & Hooks](04_PATCHING_AND_HOOKS.md)** - Integración
- Cómo se interceptan métodos
- Ruby method aliasing
- Before/after hooks
- Recuperación de errores
- Patrones comunes

### 5. **[Data API](05_DATA_API.md)** - Acceso a Datos
- Provider pattern para datos
- Gen-6 vs era GameData (GameData)
- Fallback provider
- Caching y rendimiento
- Tabla de mapeo

### 6. **[Pathfinding](06_PATHFINDING.md)** - Búsqueda de Rutas
- Algoritmo A*
- Detección de ledges
- HPA* (Hierarchical Pathfinding)
- Flood reachability
- Memoización
- Configuración de usuario

### 7. **[Audio3D](07_AUDIO3D.md)** - Sonido Posicional
- Steam Audio y HRTF Binaural
- PA3D_steam.dll
- Detectores de sonido (emitters)
- Oclusión (paredes)
- Sample rates (44100 vs 48000)
- Integración con navegación

## 📖 Documentos de Sistema

### 8. **[Loading System](09_LOADING_SYSTEM.md)** - Inicio del Programa
- Flujo de carga completo
- Preload script vs Boot script
- Manifests y orden de dependencias
- Archivos de configuración
- Recuperación de errores
- Ruby eval() y TOPLEVEL_BINDING

### 9. **[Ruby Fundamentals](08_RUBY_FUNDAMENTALS.md)** - Conceptos de Ruby
- Módulos y métodos de clase
- Bloques y yields
- Hash, Array, Symbol
- Instance variables
- Alias_method (wrapping)
- Rescue (manejo de errores)
- Define_method (creación dinámica)
- **Leer si no conoces Ruby**

## 📋 Referencia Rápida

### 10. **[API Reference](10_API_REFERENCE.md)** - Métodos Principales
- PokeAccess::Config - Configuración
- PokeAccess::Engine - Detección
- PokeAccess::Data - Acceso a datos
- PokeAccess::Pathfinder - Rutas
- PokeAccess::Audio3D - Audio 3D
- PokeAccess.speak - Síntesis de voz
- PokeAccess::Events - Bus de eventos
- PokeAccess::Hooks - Sistema de hooks
- PokeAccess::Tags - Etiquetas de usuario
- PokeAccess::Locator - Búsqueda de objetos

### 11. **[Dependencies Tree](11_DEPENDENCIES_TREE.md)** - Árbol de Dependencias
- Gráfico de qué depende de qué
- Orden de carga
- Importancia de cada módulo
- Cómo se extiende el sistema

## 🧭 Guías y Extensión

### 12. **[Guía de Lectura](13_READING_GUIDE.md)** - Mapa Personalizado
- Qué leer según tu objetivo concreto
- Rutas de lectura por meta

### 13. **[Extender el Mod](14_EXTENDING.md)** - Hooks, Lectores, Puzzles y Perfiles
- Cómo añadir accesibilidad a una pantalla nueva sin tocar el core
- Añadir lectores, puzzles y perfiles de juego

### 14. **[Voz e i18n](15_SPEECH_AND_I18N.md)** - Cómo Hablar y Localizar
- Sistema de voz (`core/speech/`)
- Localización de strings (`lang/*.txt`)

### 15. **[Menú de Configuración](16_CONFIG_MENU.md)** - config_menu
- El menú hablado que el usuario abre sobre el juego
- Opciones disponibles y cómo se persisten

## 🎯 Lectura por Rol

### Si eres **Usuario de PokeEssentialsAccess**
1. [Quick Start](00_QUICK_START.md)
2. [Introducción](01_INTRODUCTION.md)
3. [Menú de Configuración](16_CONFIG_MENU.md)

### Si eres **Desarrollador del Juego**
1. [Introducción](01_INTRODUCTION.md)
2. [Arquitectura](02_ARCHITECTURE.md) - Entender estructura
3. [Engine Detection](03_ENGINE_DETECTION.md) - Saber qué versión es
4. [Extender el Mod](14_EXTENDING.md) - Cómo personalizar

### Si eres **Contributor a PokeEssentialsAccess**
1. Todos los anteriores +
2. [Patching & Hooks](04_PATCHING_AND_HOOKS.md)
3. [Loading System](09_LOADING_SYSTEM.md)
4. [API Reference](10_API_REFERENCE.md)
5. [Dependencies Tree](11_DEPENDENCIES_TREE.md)
6. [Ruby Fundamentals](08_RUBY_FUNDAMENTALS.md)
7. [Extender el Mod](14_EXTENDING.md)
8. [Voz e i18n](15_SPEECH_AND_I18N.md)

### Si Necesitas Entender **Un Subsistema Específico**
- **Rutas**: [Pathfinding](06_PATHFINDING.md)
- **Audio**: [Audio3D](07_AUDIO3D.md)
- **Datos**: [Data API](05_DATA_API.md)
- **Versiones**: [Engine Detection](03_ENGINE_DETECTION.md)
- **Integración**: [Patching & Hooks](04_PATCHING_AND_HOOKS.md)
- **Inicio**: [Loading System](09_LOADING_SYSTEM.md)

## 🗂️ Estructura de Carpetas Documentadas

```
PokeEssentialsAccess/
├── core/                        ← Documentado en: [Arquitectura](02_ARCHITECTURE.md)
│   ├── foundation/              ← [Patching & Hooks](04_PATCHING_AND_HOOKS.md)
│   ├── data/                    ← [Data API](05_DATA_API.md)
│   ├── speech/                  ← [Arquitectura](02_ARCHITECTURE.md) (síntesis + markers)
│   ├── input/                   ← [Patching & Hooks](04_PATCHING_AND_HOOKS.md)
│   ├── nav/                     ← [Pathfinding](06_PATHFINDING.md)
│   ├── audio/                   ← [Audio3D](07_AUDIO3D.md)
│   ├── battle/                  ← [Engine Detection](03_ENGINE_DETECTION.md)
│   ├── menus/                   ← [Patching & Hooks](04_PATCHING_AND_HOOKS.md)
│   ├── dialogue/                ← [Extender el Mod](14_EXTENDING.md)
│   ├── field/                   ← [Extender el Mod](14_EXTENDING.md)
│   ├── party/                   ← [Extender el Mod](14_EXTENDING.md)
│   ├── puzzles/                 ← [Extender el Mod](14_EXTENDING.md)
│   └── util/                    ← [Arquitectura](02_ARCHITECTURE.md)
│
├── games/<nombre>/              ← Documentado en: [Arquitectura](02_ARCHITECTURE.md)
│   ├── constants.rb             ← Define juego
│   └── manifest.rb              ← Lista de módulos
│
├── loader/                      ← Documentado en: [Loading System](09_LOADING_SYSTEM.md)
│   ├── boot.rb                  ← Cargador principal
│   ├── preload_access.rb        ← Preload script
│   └── Loader.rb                ← Alternativa RMXP
│
├── native/                      ← Documentado en: [Audio3D](07_AUDIO3D.md)
│   ├── pa3d_steam.c             ← Código C de la DLL
│   └── pa3d.def                 ← Definiciones
│
└── docs/                        ← TÚ ESTÁS AQUÍ
    ├── 00_QUICK_START.md
    ├── 01_INTRODUCTION.md
    ├── 02_ARCHITECTURE.md
    ├── 03_ENGINE_DETECTION.md
    ├── 04_PATCHING_AND_HOOKS.md
    ├── 05_DATA_API.md
    ├── 06_PATHFINDING.md
    ├── 07_AUDIO3D.md
    ├── 08_RUBY_FUNDAMENTALS.md
    ├── 09_LOADING_SYSTEM.md
    ├── 10_API_REFERENCE.md
    ├── 11_DEPENDENCIES_TREE.md
    ├── 12_INDEX.md (TÚ ESTÁS AQUÍ)
    ├── 13_READING_GUIDE.md
    ├── 14_EXTENDING.md
    ├── 15_SPEECH_AND_I18N.md
    ├── 16_CONFIG_MENU.md
    └── _index.md
```

## 🔍 Cómo Buscar

### Por Tema
- **Configuración**: [Menú de Configuración](16_CONFIG_MENU.md)
- **Errores**: [Loading System](09_LOADING_SYSTEM.md#recuperación-de-errores)
- **Rendimiento**: [Pathfinding](06_PATHFINDING.md#rendimiento), [Architecture](02_ARCHITECTURE.md#rendimiento)
- **Debugging**: [Loading System](09_LOADING_SYSTEM.md#diagnóstico)

### Por Clase/Módulo
- `PokeAccess::Config` → [Architecture](02_ARCHITECTURE.md#capa-1-foundation), [Menú de Configuración](16_CONFIG_MENU.md)
- `PokeAccess::Engine` → [Engine Detection](03_ENGINE_DETECTION.md)
- `PokeAccess::Data` → [Data API](05_DATA_API.md)
- `PokeAccess::Pathfinder` → [Pathfinding](06_PATHFINDING.md)
- `PokeAccess::Audio3D` → [Audio3D](07_AUDIO3D.md)
- `PokeAccess::Hooks` → [Patching & Hooks](04_PATCHING_AND_HOOKS.md)

## 📝 Glosario Rápido

- **Gen-6**: Essentials v16-v17 (viejo). Ver [Engine Detection](03_ENGINE_DETECTION.md).
- **Era GameData**: Essentials v19+ (nuevo). Ver [Engine Detection](03_ENGINE_DETECTION.md).
- **GameData**: API de datos en Essentials (era GameData). Ver [Data API](05_DATA_API.md).
- **Provider**: Adaptador para diferentes versiones. Ver [Data API](05_DATA_API.md).
- **Hook**: Interceptar un método sin modificar el archivo. Ver [Patching & Hooks](04_PATCHING_AND_HOOKS.md).
- **A***: Algoritmo de búsqueda de ruta. Ver [Pathfinding](06_PATHFINDING.md).
- **HRTF**: Audio 3D binaural. Ver [Audio3D](07_AUDIO3D.md).
- **Manifest**: Lista ordenada de módulos a cargar. Ver [Loading System](09_LOADING_SYSTEM.md).
- **Preload**: Script que se ejecuta ANTES del juego. Ver [Loading System](09_LOADING_SYSTEM.md).
- **eval()**: Ejecutar código Ruby como string. Ver [Ruby Fundamentals](08_RUBY_FUNDAMENTALS.md).
- **Emitter**: Fuente de sonido 3D. Ver [Audio3D](07_AUDIO3D.md).
- **Oclusión**: Sonido amortiguado al atravesar paredes. Ver [Audio3D](07_AUDIO3D.md).

## 🚀 Próximos Pasos

1. **Lee [Introducción](01_INTRODUCTION.md)** - Entiende qué es PokeEssentialsAccess
2. **Lee [Arquitectura](02_ARCHITECTURE.md)** - Aprende la estructura
3. **Elige tu camino** según tu rol (arriba)
4. **Consulta referencia rápida** cuando necesites detalles

## 📞 Estructura de Capas (Resumen Visual)

```
┌─────────────────────────────────┐
│ Juego Específico (games/<name>)│  ← Personalización por juego
├─────────────────────────────────┤
│ Motor Específico (core/*/v21/)  │  ← Adaptadores por versión
├─────────────────────────────────┤
│ Core Compartido (core/*/*)      │  ← Lógica universal
├─────────────────────────────────┤
│ Pokemon Essentials + MKXP-Z     │  ← Base del juego
└─────────────────────────────────┘
```

**Documentado en**: [Arquitectura](02_ARCHITECTURE.md#capas-de-la-arquitectura)

## 📖 Lectura Recomendada Completa

**Tiempo estimado: 4-6 horas de lectura**

1. [Introducción](01_INTRODUCTION.md) - 30 min
2. [Ruby Fundamentals](08_RUBY_FUNDAMENTALS.md) - 1 hora (si no sabes Ruby)
3. [Arquitectura](02_ARCHITECTURE.md) - 1 hora
4. [Engine Detection](03_ENGINE_DETECTION.md) - 45 min
5. [Data API](05_DATA_API.md) - 45 min
6. [Patching & Hooks](04_PATCHING_AND_HOOKS.md) - 1 hora
7. [Pathfinding](06_PATHFINDING.md) - 1 hora
8. [Audio3D](07_AUDIO3D.md) - 1 hora
9. [Loading System](09_LOADING_SYSTEM.md) - 45 min
10. [API Reference](10_API_REFERENCE.md) - 30 min (referencia)
11. [Dependencies Tree](11_DEPENDENCIES_TREE.md) - 30 min (referencia)

## 🎯 Metas de Aprendizaje

✅ **Después de leer esta documentación, podrás**:

- [ ] Explicar qué es PokeEssentialsAccess y cómo funciona
- [ ] Entender por qué hay múltiples versiones de Essentials
- [ ] Leer y modificar código Ruby con módulos y bloques
- [ ] Entender cómo se cargan los módulos en orden
- [ ] Saber qué es un hook y cómo se usa
- [ ] Explicar cómo el pathfinder encuentra rutas
- [ ] Describir cómo funciona el audio 3D
- [ ] Debuguear problemas usando logs y diag.txt
- [ ] Entender cómo extender PokeEssentialsAccess

---

**Versión**: 1.0  
**Última actualización**: 2026-06-22  
**Escritura**: 100% documentación (sin código ejecutable)

¡Bienvenido a la documentación de PokeEssentialsAccess! 🎮📚
