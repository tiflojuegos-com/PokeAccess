# Guía de Lectura - Mapa Personalizado

Esta guía te ayuda a encontrar exactamente qué leer según tu objetivo.

## 🎯 ¿Cuál es tu rol?

### 👤 Yo soy: **Usuario que juega con PokeEssentialsAccess**

**Objetivo**: Usar PokeEssentialsAccess correctamente, entender opciones de accesibilidad

**Ruta de Lectura**:
```
1. [Introducción](01_INTRODUCTION.md)          [5 min]
   └─ ¿Qué es PokeAccess?
   
2. Documentación de Opciones (por hacer)      [10 min]
   └─ Explicación de cada opción
   
3. [API Reference](10_API_REFERENCE.md)       [5 min]
   └─ Comandos rápidos de teclado
```

**Tiempo total**: 20 minutos

---

### 🛠️ Yo soy: **Desarrollador de Juego que usa PokeEssentialsAccess**

**Objetivo**: Integrar PokeEssentialsAccess en tu juego, personalizarlo

**Ruta de Lectura**:
```
1. [Introducción](01_INTRODUCTION.md)              [10 min]
   └─ Contexto general
   
2. [Arquitectura](02_ARCHITECTURE.md) - Capas    [20 min]
   └─ Ver dónde va tu personalización
   
3. [Engine Detection](03_ENGINE_DETECTION.md)     [15 min]
   └─ Entender qué versión de Essentials
   
4. Game-Specific Layers (por hacer)               [20 min]
   └─ Cómo crear games/<tuJuego>/
   
5. [API Reference](10_API_REFERENCE.md)           [10 min]
   └─ Qué métodos están disponibles
```

**Tiempo total**: 75 minutos (1.5 horas)

---

### 👨‍💻 Yo soy: **Contributor/Desarrollador de PokeEssentialsAccess**

**Objetivo**: Entender completamente la arquitectura, agregar features, corregir bugs

**Ruta de Lectura COMPLETA**:

```
NIVEL 1: Foundation (1.5 horas)
─────────────────────────────
1. [Introducción](01_INTRODUCTION.md)              [10 min]
   └─ Contexto del proyecto

2. [Ruby Fundamentals](08_RUBY_FUNDAMENTALS.md)   [1 hora]
   └─ Módulos, bloques, metaprogramming
   
3. [Loading System](09_LOADING_SYSTEM.md)         [30 min]
   └─ Cómo se carga todo

NIVEL 2: Architecture (1.5 horas)
──────────────────────────────────
4. [Arquitectura](02_ARCHITECTURE.md)             [1 hora]
   └─ Capas y estructura

5. [Engine Detection](03_ENGINE_DETECTION.md)     [30 min]
   └─ Versiones de Essentials

NIVEL 3: Core Systems (2 horas)
────────────────────────────────
6. [Patching & Hooks](04_PATCHING_AND_HOOKS.md)   [1 hora]
   └─ Sistema de extensión

7. [Data API](05_DATA_API.md)                      [1 hora]
   └─ Provider pattern

NIVEL 4: Navigation & Audio (2.5 horas)
─────────────────────────────────────────
8. [Pathfinding](06_PATHFINDING.md)               [1.5 horas]
   └─ Algoritmos A* y HPA*

9. [Audio3D](07_AUDIO3D.md)                        [1 hora]
   └─ Steam Audio y HRTF

NIVEL 5: Reference (1 hora)
─────────────────────────────
10. [API Reference](10_API_REFERENCE.md)          [30 min]
    └─ Quick lookup

11. [Dependencies Tree](11_DEPENDENCIES_TREE.md)  [30 min]
    └─ Cómo todo se conecta

TOTAL: 9.5 horas
```

**Recomendación**: Leer en 2-3 sesiones, experimentar en el código entre sesiones

---

## 📍 ¿Necesitas entender un SUBSISTEMA específico?

### 🗺️ Subsistema: **Navegación por Rutas**

**Documentos necesarios**:
```
[Pathfinding](06_PATHFINDING.md)
  ├─ Algoritmo A*
  ├─ Detección de ledges
  ├─ Caching y performance
  └─ Configuración

[Architecture](02_ARCHITECTURE.md) - Capa 4 (Navigation)
  └─ Cómo se integra

[API Reference](10_API_REFERENCE.md) - PokeAccess::Pathfinder
  └─ Métodos disponibles

[Dependencies Tree](11_DEPENDENCIES_TREE.md) - "Sistema de Pathfinding"
  └─ Qué depende de qué
```

**Tiempo**: 1.5 horas

---

### 🎵 Subsistema: **Audio 3D**

**Documentos necesarios**:
```
[Audio3D](07_AUDIO3D.md)
  ├─ HRTF Binaural
  ├─ Steam Audio
  ├─ Emitters y oclusión
  └─ Integración

[Architecture](02_ARCHITECTURE.md) - Capas Audio
  └─ Cómo se integra

[API Reference](10_API_REFERENCE.md) - PokeAccess::Audio3D
  └─ Métodos

[Dependencies Tree](11_DEPENDENCIES_TREE.md) - "Sistema de Audio 3D"
  └─ Qué usa Audio3D
```

**Tiempo**: 1.5 horas

---

### 🔄 Subsistema: **Versiones de Essentials**

**Documentos necesarios**:
```
[Engine Detection](03_ENGINE_DETECTION.md)
  ├─ Gen-6 vs era GameData
  ├─ v22 UI rework
  ├─ Sky fork
  └─ Árbol de decisión

[Architecture](02_ARCHITECTURE.md)
  ├─ Capas versión-específicas
  └─ Patrones para múltiples versiones

[Patching & Hooks](04_PATCHING_AND_HOOKS.md)
  └─ Cómo cada versión tiene hooks propios

[Data API](05_DATA_API.md)
  └─ Provider pattern para datos

[Dependencies Tree](11_DEPENDENCIES_TREE.md)
  └─ gen6/ vs v21/ vs v22/
```

**Tiempo**: 2 horas

---

### 🎮 Subsistema: **Sistema de Datos**

**Documentos necesarios**:
```
[Data API](05_DATA_API.md)
  ├─ Provider pattern
  ├─ Gen-6 vs era GameData
  ├─ Fallback
  └─ Caching

[Engine Detection](03_ENGINE_DETECTION.md)
  └─ Cómo elige provider

[API Reference](10_API_REFERENCE.md) - PokeAccess::Data
  └─ Métodos: species_name(), move_power(), etc.

[Dependencies Tree](11_DEPENDENCIES_TREE.md) - "Sistema de Datos"
  └─ Qué usa Data
```

**Tiempo**: 1 hora

---

## 🔧 ¿Quieres HACER algo específico?

### 🎯 Tarea: Agregar nueva opción de configuración

**Pasos**:
1. Lee [Config Schema](#) (por hacer)
2. Edita `core/foundation/config.rb`
3. Lee [Patching & Hooks](04_PATCHING_AND_HOOKS.md) para entender cómo usarla
4. Lee [API Reference](10_API_REFERENCE.md) - PokeAccess::Config

**Tiempo**: 30 minutos

---

### 🎯 Tarea: Soportar nueva versión de Essentials

**Pasos**:
1. Lee [Engine Detection](03_ENGINE_DETECTION.md) - Completo
2. Lee [Architecture](02_ARCHITECTURE.md) - Capas versión-específicas
3. Agrega nueva carpeta: `core/battle/v23/`
4. Lee [Patching & Hooks](04_PATCHING_AND_HOOKS.md) - Implementar hooks
5. Lee [Loading System](09_LOADING_SYSTEM.md) - Agregar a manifest
6. Lee [Dependencies Tree](11_DEPENDENCIES_TREE.md) - Validar orden

**Tiempo**: 2-3 horas

---

### 🎯 Tarea: Crear adaptador para sistema de batalla personalizado

**Pasos**:
1. Lee [Patching & Hooks](04_PATCHING_AND_HOOKS.md) - Completo
2. Lee [Engine Detection](03_ENGINE_DETECTION.md) - Detectar tu sistema
3. Lee `core/battle/battle.rb` - Lógica compartida
4. Lee `core/battle/v21/battle_v21.rb` - Ejemplo
5. Crea tu archivo de hooks
6. Lee [Loading System](09_LOADING_SYSTEM.md) - Agregar a manifest

**Tiempo**: 2 horas

---

### 🎯 Tarea: Debuguear error en carga

**Pasos**:
1. Lee [Loading System](09_LOADING_SYSTEM.md) - Diagnóstico
2. Revisa `accessibility/data/loader_error.txt`
3. Lee [Dependencies Tree](11_DEPENDENCIES_TREE.md) - Validar orden
4. Lee [Ruby Fundamentals](08_RUBY_FUNDAMENTALS.md) - Si no entiendes error

**Tiempo**: 30 minutos

---

## ⏱️ Ruta Rápida por Tiempo Disponible

### ⚡ Tengo 30 minutos
```
1. [Introducción](01_INTRODUCTION.md)
2. [API Reference](10_API_REFERENCE.md)

Resultado: Entendimiento básico + referencia rápida
```

### ⚡ Tengo 1 hora
```
1. [Introducción](01_INTRODUCTION.md)
2. [Engine Detection](03_ENGINE_DETECTION.md)
3. [API Reference](10_API_REFERENCE.md)

Resultado: Entender versiones + referencia de métodos
```

### ⚡ Tengo 2 horas
```
1. [Introducción](01_INTRODUCTION.md)
2. [Arquitectura](02_ARCHITECTURE.md)
3. [Engine Detection](03_ENGINE_DETECTION.md)
4. [API Reference](10_API_REFERENCE.md)

Resultado: Estructura completa + métodos
```

### ⚡ Tengo 4 horas
```
1. [Introducción](01_INTRODUCTION.md)
2. [Ruby Fundamentals](08_RUBY_FUNDAMENTALS.md)
3. [Arquitectura](02_ARCHITECTURE.md)
4. [Engine Detection](03_ENGINE_DETECTION.md)
5. [Data API](05_DATA_API.md)
6. [API Reference](10_API_REFERENCE.md)

Resultado: Arquitectura profunda + subsistemas clave
```

### ⚡ Tengo 8+ horas
```
Lee TODO (ruta de contributor completa arriba)
Resultado: Experto en PokeAccess
```

---

## 🎓 Plan de Estudio Recomendado

### Semana 1: Fundamentos
```
Día 1: Introducción + Ruby (2 horas)
Día 2: Loading System + Architecture (2 horas)
Día 3: Engine Detection (1.5 horas)
Día 4: Descanso / Experimentación
Día 5: Repaso + API Reference (1 hora)

Total: 6.5 horas
```

### Semana 2: Sistemas
```
Día 1: Patching & Hooks (1 hora)
Día 2: Data API (1 hora)
Día 3: Pathfinding (1.5 horas)
Día 4: Audio3D (1.5 horas)
Día 5: Dependencies Tree (1 hora)

Total: 6 horas
```

### Semana 3: Práctica
```
Día 1-5: Experimenta en el código
- Agregar opción de config
- Crear un hook personalizado
- Extender para nueva versión

Total: Según progreso
```

---

## ✅ Checklist: ¿Qué has Entendido?

Después de leer esta documentación, deberías poder:

**Después de [Introducción](01_INTRODUCTION.md)**:
- [ ] Explicar qué es PokeEssentialsAccess
- [ ] Describir por qué MKXP-Z es importante
- [ ] Listar los 3 objetivos principales del proyecto

**Después de [Ruby Fundamentals](08_RUBY_FUNDAMENTALS.md)**:
- [ ] Explicar módulos vs clases
- [ ] Usar bloques con { |x| ... }
- [ ] Entender alias_method
- [ ] Usar instance_variable_get/set

**Después de [Arquitectura](02_ARCHITECTURE.md)**:
- [ ] Dibujar las 7 capas
- [ ] Explicar qué hace cada capa
- [ ] Saber dónde agregar nuevo código

**Después de [Engine Detection](03_ENGINE_DETECTION.md)**:
- [ ] Saber diferenciar Gen-6 vs era GameData
- [ ] Explicar cómo Engine.kind se detecta
- [ ] Saber cuándo se usan hooks de gen6 vs v21

**Después de [Data API](05_DATA_API.md)**:
- [ ] Explicar provider pattern
- [ ] Saber cómo obtener nombre de Pokémon
- [ ] Entender prioridades de providers

**Después de [Pathfinding](06_PATHFINDING.md)**:
- [ ] Explicar A* en 3 frases
- [ ] Saber por qué hay caché
- [ ] Entender detección de ledges

**Después de [Audio3D](07_AUDIO3D.md)**:
- [ ] Explicar HRTF Binaural
- [ ] Saber qué es un emitter
- [ ] Entender oclusión

**Después de [Loading System](09_LOADING_SYSTEM.md)**:
- [ ] Explicar diferencia preload vs boot
- [ ] Saber dónde van los módulos
- [ ] Entender por qué el orden importa

---

## 📞 Preguntas Frecuentes de Lectura

**P: Tengo que leer TODO?**
R: No. Depende de tu rol (arriba hay rutas personalizadas)

**P: ¿Está incompleta la documentación?**
R: Sí, faltan documentos "Game-Specific Layers", "Config Options", etc.
Se añadirán próximamente.

**P: ¿En qué orden leo si no sé Ruby?**
R: 1. Ruby Fundamentals 2. Introducción 3. Lo demás

**P: ¿Es necesario entender Steam Audio para contribuir?**
R: No, solo si trabajas en audio 3D. Para batalla/menús, no necesitas.

**P: ¿Debo tener VS Code abierto mientras leo?**
R: Recomendado. Te ayuda a ver ejemplos reales mientras estudias.

---

Volver a [Índice](12_INDEX.md)
