# PokeEssentialsAccess

Mod de accesibilidad para fangames de Pokémon. Permite que una persona ciega pueda jugarlos con lector de pantalla.

---

## Índice

- [¿Qué es esto?](#qué-es-esto)
- [¿Qué añade?](#qué-añade)
- [Teclas del mod](#teclas-del-mod)
- [Estructura del mod](#estructura-del-mod)
- [Documentación](#documentación)
- [Licencia](#licencia)

---

## ¿Qué es esto?

Es un mod para accesibilizar fangames hechos a partir de la base de **Pokémon Essentials** (Essentials v16 o superior), permitiendo a una persona ciega poder jugarlos.

## ¿Qué añade?

Este mod añade lo siguiente:

- **Lectura de textos** (menús, diálogos, combates, etc.).
- **Navegación sonora** (audio 3D posicional para orientarte).
- **Búsqueda de rutas** (te guía hasta el objetivo que elijas).
- **Remapeo de teclas** dentro de los juegos.
- **Accesibilización de puzzles**. Esto último hay que hacerlo juego a juego; de momento hay soporte en:
  - Pokémon Z
  - Pokémon Ópalo

## Teclas del mod

> **Recomendación:** conviene remapear las teclas de serie de los juegos para navegar con más comodidad. Una configuración cómoda es asignar el **movimiento** a `W`, `A`, `S`, `D`, **confirmar** a `E` y **cancelar** a `Q`.

Estas son las teclas por defecto que añade el mod:

| Tecla | Acción |
|-------|--------|
| `I` | Calcular la ruta hacia el objetivo seleccionado |
| `J` | Objetivo anterior de la lista |
| `L` | Objetivo siguiente de la lista |
| `K` | Anunciar el objetivo seleccionado  |
| `T` | Leer la información del objetivo / de la escena |
| `H` | Leer los PS (puntos de salud) en combate |
| `G` | Leer las condiciones del terreno en combate |
| `M` | Leer las coordenadas actuales |
| `O` | Abrir el menú de configuración del mod |

### Modificadores

Combinados con las teclas de arriba amplían su función:

| Combinación | Acción |
|-------------|--------|
| `Shift` + `J` / `L` | Cambiar de categoría de objetivos (personas, objetos, salidas, etc.) |
| `Shift` + `K` | Renombrar el objetivo seleccionado |
| `Shift` + `I` | Activar/desactivar la guía sonora hacia el objetivo |
| `Ctrl` + `K` | Abrir el menú de etiquetas del objetivo |
| `Shift` + `T` | Repetir el último diálogo leído |

### Atajos globales

| Combinación | Acción |
|-------------|--------|
| `Ctrl` + `Alt` + `F8` | Activar / desactivar el mod |
| `Ctrl` + `Alt` + `F9` | Volcar un diagnóstico a un archivo (útil por si se encuentran pantallas, puzzles o mapas inaccesibles) |
| `Ctrl` + `Alt` + `F10` | Diagnóstico hablado rápido (útil si algo se queda en silencio) |

## Estructura del mod

Estas son las carpetas principales del repositorio y qué contienen:

| Carpeta | Contenido |
|---------|-----------|
| `core/` | El motor compartido del mod, agnóstico al juego. Se organiza por módulos, y dentro por versión de Essentials (`gen6`, `v21`, `v22`, `skyflyer`) cuando hace falta. |
| `games/` | Un perfil por juego: sus lectores específicos y su configuración. Cada carpeta es un fangame soportado (`pokemon_z`, `opalo`, `anil`, `relict`, etc.). |
| `lang/` | Los textos que habla el mod, traducidos (`es.txt` español, `en.txt` inglés). |
| `loader/` | El script que inyecta el mod en el juego al arrancar. |
| `native/` | Bibliotecas nativas (la librería de audio  y el puente con el lector). |
| `installer/` | El instalador que copia el mod dentro de un juego. |
| `assets/` | Recursos (sonidos y datos que acompañan al mod). |
| `test/` | La batería de tests del mod y sus utilidades. |
| `docs/` | La documentación técnica completa (ver abajo). |

Dentro de `core/`, cada módulo agrupa una responsabilidad: `input/` (teclas y enganches), `nav/` (navegación y rutas), `audio/` (sonido 3D), `menus/`, `battle/`, `party/`, `field/`, `speech/` (voz), `foundation/` (base), etc.

## Documentación

La documentación (arquitectura, sistema de enganches, API, guía para extender el mod, etc.) está en la carpeta **[`docs/`](docs/)**.

Buenos puntos de entrada:

- **[docs/00_QUICK_START.md](docs/00_QUICK_START.md)** — resumen en 5 minutos.
- **[docs/_index.md](docs/_index.md)** — índice de toda la documentación.

## Licencia

Este proyecto es software libre bajo la licencia **[MIT](LICENSE)**: puedes usarlo, modificarlo y redistribuirlo libremente manteniendo el aviso de copyright.

Las bibliotecas nativas de terceros incluidas en `assets/` conservan sus propias licencias.
