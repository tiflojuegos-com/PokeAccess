# El menú de configuración (config_menu)

PokeEssentialsAccess trae un **menú de configuración hablado** que el usuario abre sobre el juego en marcha. Esta es
la referencia para desarrolladores: cómo está estructurado, cómo se definen las opciones y qué controla
cada ajuste de audio 3D y voz.

> Código: `core/menus/config_menu.rb` (el menú) y `core/foundation/config.rb` (el esquema de opciones).
> Relacionado: [15_SPEECH_AND_I18N.md](15_SPEECH_AND_I18N.md), [07_AUDIO3D.md](07_AUDIO3D.md).

---

## 1. Cómo funciona

`ConfigMenu` corre como un **bucle modal** sobre el mapa: cuando se abre, toma `Graphics.update`/
`Input.update` y pausa el juego (jugador, pasos, audio posicional) hasta cerrarse. Lee los **botones del
propio juego**, así que se navega con los controles del jugador y cualquier rebind funciona gratis.

Tiene dos niveles: una **lista de categorías** y, dentro de cada una, sus ajustes. Acciones (con las teclas
del mod):

| Acción | Efecto |
|--------|--------|
| `:prev` / `:next` | Mover por la lista |
| `:where` / `:route` | Bajar/subir un valor numérico, alternar un flag, ciclar idioma, entrar a una categoría o ejecutar una acción |
| `:info` | Leer la ayuda del ajuste enfocado |
| `:config` | Volver un nivel, o cerrar desde el nivel superior |

Cada etiqueta y mensaje es una **clave i18n** (nada hardcodeado). Al cerrar, persiste con
`Settings.write`.

---

## 2. El esquema de opciones (`Config::SCHEMA`)

Las opciones del usuario se declaran en una tabla `SCHEMA` en `core/foundation/config.rb`. Cada fila es:

```ruby
[clave, valor_por_defecto, tipo, categoría, lbl_etiqueta, help_ayuda]
```

- **clave** — el símbolo del ajuste (`Config.audio3d_volume`, etc.).
- **valor_por_defecto** — el valor inicial.
- **tipo** — cómo se edita y se lee. Numéricos (`:vol`, `:tiles`, `:sec`, `:ms`, `:reach`, `:astar`, `:gdist`, `:desk`)
  usan `KIND_BOUNDS` `[min, max, paso, unidad]`; no numéricos (`:flag`, `:lang`, `:navmode`, `:occ`,
  `:algo`) tienen su propia edición.
- **categoría** — en qué submenú aparece (`:general`, `:pathfinder`, `:audio`, o las sub-categorías de
  audio posicional `:audio3d_vol`/`:audio3d_freq`/`:audio3d_walls`/`:audio3d_adv`).
- **lbl_/help_** — claves i18n del nombre y de la ayuda (la que dice `:info`).

Las categorías de primer nivel están en `Config::CATEGORIES` (`:general`, `:pathfinder`, `:audio`); la de
audio abre además las sub-categorías de audio 3D. El menú raíz añade además, fuera de `CATEGORIES`, las
entradas Tags, Remapear, **Depuración** y Restaurar (las empuja `config_menu.rb` a mano). Para **añadir una
opción** basta con una fila nueva en `SCHEMA` + sus claves `lbl_`/`help_` en `lang/es.txt` y `lang/en.txt`
(paridad); aparece en su categoría automáticamente.

### Menú de Depuración

Entrada del menú raíz (`:debug`) para desarrollo y soporte. No es para el usuario final típico, pero es
accesible. Contiene:

- **Diagnósticos por sección al portapapeles**: audio 3D / eventos y localizador / rendimiento / mapa y
  navegación / escena y runtime. Cada uno copia solo su sección (vía `Clipboard.set_text`) para pegarla
  donde haga falta sin volcar todo. Un **Diagnóstico completo** escribe a `accessibility/data/diag.txt` (igual
  que Ctrl+Alt+F9, que se mantiene como atajo).
- **Ajustes avanzados** del grupo `:debug` del SCHEMA: `transfer_active_page_only` (anunciar una baldosa
  como salida solo si su página activa transfiere) y `route_auto` + `route_budget_ms` (corte del busca-rutas
  por tiempo en vez de por nodos; ver [06_PATHFINDING.md](06_PATHFINDING.md)). Todos OFF/seguros por defecto.

---

## 3. Ajustes de voz y navegación

| Ajuste | Defecto | Qué hace |
|--------|---------|----------|
| `language` | `:es` | Idioma de la voz del mod (cicla por los `lang/*.txt`). |
| `sound_nav` | `:full` | Modo de navegación por sonido: `:full` (todos los emisores), modos reducidos, `:off` (solo pasos y choques). |
| `proximity_radar` | `false` | Radar de proximidad. |
| `auto_detect` | `true` | Lectura automática de ventanas `Window_Selectable` sin lector dedicado. |
| `auto_guide` | `false` | Guía automática hacia el objetivo seleccionado. |
| `name_items` | `true` | Nombrar objetos del suelo. |

---

## 4. Ajustes de audio 3D (Steam Audio)

El audio 3D paneа emisores por HRTF; el detalle del motor está en [07_AUDIO3D.md](07_AUDIO3D.md). Lo que
el usuario ajusta desde el menú:

**Volúmenes** (`:vol`, 0-100, paso 10) — categoría `audio` y sub-categoría `audio3d_vol`:

| Ajuste | Defecto | Qué suena |
|--------|---------|-----------|
| `audio3d_volume` | 80 | Volumen maestro del audio posicional. |
| `audio3d_npc` / `audio3d_object` / `audio3d_door` | 85 | Pings de NPCs / objetos / puertas. |
| `audio3d_teleporter` | 90 | Teletransportadores. |
| `audio3d_water` / `audio3d_wind` | 70 / 55 | Bucles de agua / viento. |
| `footstep_volume` / `wall_volume` / `event_volume` | 80 / 80 / 70 | Pasos / choque con pared / cue de guía. |

**Frecuencia de pings** (`:vol`, sub-categoría `audio3d_freq`) — cada cuánto suena cada tipo:
`audio3d_freq_npc` / `audio3d_freq_object` / `audio3d_freq_door` (70) y `guide_freq` (55).

**Paredes y oclusión** (sub-categoría `audio3d_walls`):

| Ajuste | Defecto | Qué hace |
|--------|---------|----------|
| `audio3d_occlusion` | `:occlude` | Emisores tras pared: `:hear` (normal), `:occlude` (apagado), `:hide` (no suenan). |
| `audio3d_air` | `false` | Absorción de aire. |
| `audio3d_wall_range` | 3 | Alcance de detección de paredes (tiles). |
| `audio3d_wall_falloff` | 50 | Caída de volumen del viento con la distancia a la pared. |
| `audio3d_desk_range` | 2 | Distancia a la que un NPC de mostrador sigue oyéndose tras una pared (0 lo desactiva). |

**Avanzado** (sub-categoría `audio3d_adv`): `audio3d_range` (12, alcance del sonar en tiles) y
`audio3d_alt_dist` (5, distancia a la que dos emisores alternan sus pings en vez de sonar a la vez).

---

## 5. Ajustes de pathfinding

Categorías `pathfinder` / `pathfinder_adv`: `path_algorithm` (`:astar`/JPS/HPA*), `route_reach`,
`astar_max`, `guide_distance` (distancia del chime de la guía), `guide_refresh`, `straight_routes`,
`ledge_directions`, `route_cache`, `hide_unreachable`, `fixed_target_number`, etc. (`route_auto` y
`route_budget_ms` viven ahora en el menú de Depuración, ver arriba.) El detalle algorítmico está en
[06_PATHFINDING.md](06_PATHFINDING.md).

## Próximo

- [07_AUDIO3D.md](07_AUDIO3D.md) — el motor de audio posicional por dentro
- [15_SPEECH_AND_I18N.md](15_SPEECH_AND_I18N.md) — voz e i18n
