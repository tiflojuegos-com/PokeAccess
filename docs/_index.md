# 📚 Documentación de PokeEssentialsAccess

Bienvenido a la documentación técnica y explicativa completa de **PokeEssentialsAccess**, un toolkit de accesibilidad integral para fangames de Pokémon.

## 📖 ¿Por Dónde Empiezo?

### ⏱️ Tengo 5 minutos
**Lee**: [00_QUICK_START.md](00_QUICK_START.md)
Resumen ejecutivo: qué es, cómo funciona, conceptos clave.

### ⏱️ Tengo 30 minutos
**Lee**: [00_QUICK_START.md](00_QUICK_START.md) + [01_INTRODUCTION.md](01_INTRODUCTION.md)
Entendimiento general + contexto profundo.

### ⏱️ Tengo 1+ horas
**Recomendado**: [13_READING_GUIDE.md](13_READING_GUIDE.md)
Elige tu camino según tu rol (usuario, desarrollador, contributor).

### 🔍 Estoy buscando algo específico
**Consulta**: [12_INDEX.md](12_INDEX.md)
Mapa completo de documentos por tema y módulo.

---

## 📑 Índice Rápido de Documentos

### 🎯 Introducción y Conceptos
- [00_QUICK_START.md](00_QUICK_START.md) — 5 min — Resumen ejecutivo.
- [01_INTRODUCTION.md](01_INTRODUCTION.md) — 30 min — Contexto y conceptos clave.
- [08_RUBY_FUNDAMENTALS.md](08_RUBY_FUNDAMENTALS.md) — 1 hora — Fundamentos de Ruby necesarios.

### 🏗️ Arquitectura y Estructura
- [02_ARCHITECTURE.md](02_ARCHITECTURE.md) — 1 hora — Capas y estructura general.
- [03_ENGINE_DETECTION.md](03_ENGINE_DETECTION.md) — 45 min — Soporte de múltiples versiones.
- [09_LOADING_SYSTEM.md](09_LOADING_SYSTEM.md) — 45 min — Proceso de carga (boot).
- [11_DEPENDENCIES_TREE.md](11_DEPENDENCIES_TREE.md) — 30 min — Dependencias entre módulos.

### 🔌 Sistemas Core
- [04_PATCHING_AND_HOOKS.md](04_PATCHING_AND_HOOKS.md) — 1 hora — Sistema de extensión (hooks).
- [05_DATA_API.md](05_DATA_API.md) — 1 hora — Acceso agnóstico a datos.

### 🎮 Funcionalidades Principales
- [06_PATHFINDING.md](06_PATHFINDING.md) — 1.5 horas — Búsqueda de rutas (A*).
- [07_AUDIO3D.md](07_AUDIO3D.md) — 1 hora — Audio 3D posicional.

### 📋 Referencia y Guías
- [10_API_REFERENCE.md](10_API_REFERENCE.md) — 30 min — Quick lookup de métodos.
- [12_INDEX.md](12_INDEX.md) — 15 min — Índice completo por tema.
- [13_READING_GUIDE.md](13_READING_GUIDE.md) — 10 min — Rutas personalizadas por rol.
- [14_EXTENDING.md](14_EXTENDING.md) — 45 min — **Cómo añadir hooks, lectores, puzzles y perfiles** (guía práctica).
- [15_SPEECH_AND_I18N.md](15_SPEECH_AND_I18N.md) — 20 min — Voz (`speak`/`say_dialogue`), `clean`, y la convención i18n.
- [16_CONFIG_MENU.md](16_CONFIG_MENU.md) — 20 min — El menú de configuración y los ajustes de audio 3D/voz.

---

## 👥 Rutas Recomendadas por Rol

### 👤 Soy Usuario
**Objetivo**: Usar PokeEssentialsAccess correctamente
**Ruta**: 00_QUICK_START → 16_CONFIG_MENU (opciones de audio 3D/voz)
**Tiempo**: 30 minutos

### 🛠️ Soy Desarrollador de Juego
**Objetivo**: Integrar y personalizar PokeEssentialsAccess
**Ruta**: 00_QUICK_START → 01_INTRODUCTION → 02_ARCHITECTURE → 14_EXTENDING → 13_READING_GUIDE
**Tiempo**: 1.5-2 horas

### 👨‍💻 Soy Contributor
**Objetivo**: Entender completamente, agregar features
**Ruta**: [13_READING_GUIDE.md](13_READING_GUIDE.md) → Ruta Contributor completa
**Tiempo**: 8+ horas

---

## 🎯 Búsqueda por Tópico

### Entender la Estructura
- [02_ARCHITECTURE.md](02_ARCHITECTURE.md) — Capas.
- [11_DEPENDENCIES_TREE.md](11_DEPENDENCIES_TREE.md) — Qué depende de qué.
- [12_INDEX.md](12_INDEX.md) — Categorización de módulos.

### Entender Versiones de Essentials
- [03_ENGINE_DETECTION.md](03_ENGINE_DETECTION.md) — Completo.
- [02_ARCHITECTURE.md](02_ARCHITECTURE.md) — Capas versión-específicas.

### Entender Cómo Funciona
- [01_INTRODUCTION.md](01_INTRODUCTION.md) — Concepto general.
- [09_LOADING_SYSTEM.md](09_LOADING_SYSTEM.md) — Proceso de carga.
- [04_PATCHING_AND_HOOKS.md](04_PATCHING_AND_HOOKS.md) — Sistema de hooks.

### Entender Funcionalidades Específicas
- **Rutas**: [06_PATHFINDING.md](06_PATHFINDING.md)
- **Audio**: [07_AUDIO3D.md](07_AUDIO3D.md)
- **Datos**: [05_DATA_API.md](05_DATA_API.md)
- **Voz e i18n**: [15_SPEECH_AND_I18N.md](15_SPEECH_AND_I18N.md)
- **Configuración**: [16_CONFIG_MENU.md](16_CONFIG_MENU.md)

### Extender el Toolkit
- [14_EXTENDING.md](14_EXTENDING.md) — Hooks, lectores, puzzles y perfiles paso a paso.

### Referencia Rápida
- [10_API_REFERENCE.md](10_API_REFERENCE.md) — Métodos por módulo.
- [00_QUICK_START.md](00_QUICK_START.md) — Puntos clave en 5 minutos.

---

## 📝 Notas sobre la Documentación

### ✅ Completada
- Arquitectura completa.
- Sistemas core (Engine, Data, Hooks).
- Subsistemas principales (Audio, Pathfinding).
- Sistema de carga.
- Fundamentos de Ruby.
- Guía de extensión (hooks, lectores, puzzles, perfiles).
- Voz e i18n; menú de configuración.

### 🔄 En Construcción / Próximos
- Capas específicas por juego (detalle por perfil).
- Troubleshooting guide (parcial: ver §5-6 de [14_EXTENDING.md](14_EXTENDING.md) y la sección runtime del diag).
- Video tutoriales (futuro).

### 📌 Características de la Documentación
- ✅ Explicaciones técnicas profundas.
- ✅ Ejemplos de código reales del proyecto.
- ✅ Rutas personalizadas por rol.
- ✅ Glosario de términos.
- ✅ Enfoques conceptuales (no solo código).
- ✅ Estilo accesible para lectores de pantalla (lectura lineal, sin tablas anchas).

---

## 🔍 Cómo Buscar

### Por Archivo
Todos los documentos están en esta carpeta con nombres descriptivos:

- `00_QUICK_START.md` — Resumen rápido.
- `01_INTRODUCTION.md` — Introducción general.
- `02_ARCHITECTURE.md` — Estructura del proyecto.
- `03_ENGINE_DETECTION.md` — Detección de versiones.
- `04_PATCHING_AND_HOOKS.md` — Sistema de hooks.
- `05_DATA_API.md` — API de datos.
- `06_PATHFINDING.md` — Búsqueda de rutas.
- `07_AUDIO3D.md` — Audio 3D.
- `08_RUBY_FUNDAMENTALS.md` — Conceptos Ruby.
- `09_LOADING_SYSTEM.md` — Carga del sistema.
- `10_API_REFERENCE.md` — Referencia de métodos.
- `11_DEPENDENCIES_TREE.md` — Árbol de dependencias.
- `12_INDEX.md` — Índice completo por tema.
- `13_READING_GUIDE.md` — Guía de lectura por rol.
- `14_EXTENDING.md` — Cómo extender (hooks, lectores, puzzles, perfiles).
- `15_SPEECH_AND_I18N.md` — Voz y convención i18n.
- `16_CONFIG_MENU.md` — Menú de configuración (audio 3D/voz).

### Por [12_INDEX.md](12_INDEX.md)
Mapa temático completo con enlaces a secciones específicas.

### Por [13_READING_GUIDE.md](13_READING_GUIDE.md)
Búsqueda por rol, tarea, o tiempo disponible.

---

## 💡 Tips para Leer

1. **Lee en orden**: la documentación está diseñada con dependencias.
2. **Experimenta**: abre el editor y ve el código mientras lees.
3. **Usa 12_INDEX**: para saltar a temas específicos.
4. **Sigue 13_READING_GUIDE**: para tu rol específico.
5. **Consulta 10_API_REFERENCE**: para búsquedas rápidas.

---

## ❓ Preguntas Frecuentes

**P: ¿Necesito leer TODO?**
R: No. Usa [13_READING_GUIDE.md](13_READING_GUIDE.md) para tu rol.

**P: ¿Está incompleta?**
R: La mayoría está completa. Faltan documentos menores (próximas versiones).

**P: ¿Hay videos?**
R: No aún, pero está planeado para el futuro.

**P: ¿Puedo contribuir documentación?**
R: Sí. El proyecto acepta PRs de documentación.

---

## 📞 Estructura de Archivos Relacionados

```
PokeEssentialsAccess/
├── docs/                    ← TÚ ESTÁS AQUÍ
│   ├── _index.md            (este archivo)
│   ├── 00_QUICK_START.md
│   ├── 01_INTRODUCTION.md
│   ├── 02_ARCHITECTURE.md
│   ├── 03_ENGINE_DETECTION.md
│   ├── 04_PATCHING_AND_HOOKS.md
│   ├── 05_DATA_API.md
│   ├── 06_PATHFINDING.md
│   ├── 07_AUDIO3D.md
│   ├── 08_RUBY_FUNDAMENTALS.md
│   ├── 09_LOADING_SYSTEM.md
│   ├── 10_API_REFERENCE.md
│   ├── 11_DEPENDENCIES_TREE.md
│   ├── 12_INDEX.md
│   ├── 13_READING_GUIDE.md
│   ├── 14_EXTENDING.md
│   ├── 15_SPEECH_AND_I18N.md
│   └── 16_CONFIG_MENU.md
│
├── core/                    ← Código (documentado en docs/)
├── games/                   ← Perfiles de juegos específicos
├── loader/                  ← Sistema de carga
├── native/                  ← DLLs nativas
└── ...
```

---

## 🚀 Cómo Empezar Ahora

### Opción 1: Rápido (5 min)
Lee [00_QUICK_START.md](00_QUICK_START.md).

### Opción 2: Directo (30 min)
Lee [01_INTRODUCTION.md](01_INTRODUCTION.md) y consulta [10_API_REFERENCE.md](10_API_REFERENCE.md).

### Opción 3: Profundo (8 horas)
Sigue [13_READING_GUIDE.md](13_READING_GUIDE.md) → Ruta Contributor.

---

## 📚 Versión y Fecha

- **Lenguaje**: Español.
- **Audiencia**: Desarrolladores de juegos Pokémon, contributors técnicos.
- **Compilación**: Documentación pura (sin código ejecutable).

---

## 🙏 Créditos

Esta documentación fue creada para explicar completamente el proyecto PokeEssentialsAccess: su arquitectura, componentes, y filosofía de desarrollo.

---

**¿Listo para empezar?**

→ [00_QUICK_START.md](00_QUICK_START.md) (5 minutos)
→ [12_INDEX.md](12_INDEX.md) (Búsqueda)
→ [13_READING_GUIDE.md](13_READING_GUIDE.md) (Ruta personalizada)
