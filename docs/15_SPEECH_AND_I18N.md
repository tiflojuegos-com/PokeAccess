# Voz e i18n: cómo hablar y cómo localizar

Todo lo que el mod le dice al jugador pasa por dos sistemas: **voz** (`core/speech/`) y **localización**
(`core/foundation/i18n.rb` + `lang/*.txt`). Esta es la referencia para escribir lectores que hablen bien
y se traduzcan sin romper nada.

> Relacionado: [14_EXTENDING.md](14_EXTENDING.md) (cómo escribir un lector) y
> [02_ARCHITECTURE.md](02_ARCHITECTURE.md) (capa Input & Speech).

---

## 1. Hablar: `speak` y `say_dialogue`

Hay dos puntos de entrada. Casi siempre usas el primero.

### `PokeAccess.speak(text, interrupt = true)`

Manda texto al lector de pantalla activo (SRAL → NVDA/JAWS/SAPI/Narrator/ZDSR). Es la API que usan todos
los lectores de menús/pantallas.

- `interrupt = true` (por defecto): **corta** lo que se esté diciendo y dice esto ya. Para navegación de
  cursor (el usuario se movió, quiere oír la opción nueva inmediatamente).
- `interrupt = false`: **encola** detrás de lo que haya. Para líneas que no deben pisarse entre sí (varias
  líneas de combate seguidas, una lectura "al abrir" que no debe cortar el título recién dicho).

```ruby
PokeAccess.speak(PokeAccess.clean(label), true)   # opción enfocada (navegación)
PokeAccess.speak(linea_de_combate, false)         # mensaje de batalla (no cortar el anterior)
```

`speak` normaliza espacios, ignora texto vacío, y si algo falla escribe un marcador en
`accessibility/data/hook_loaded.txt` en vez de petar (nunca tumba el frame).

### `PokeAccess.say_dialogue(message)`

Para **diálogo del juego** (mensajes de `pbMessage`/`pbDisplayMessage`). Hace tres cosas que `speak` no:

1. **Limpia** el texto con `clean` (ver §2).
2. Lo guarda como "último diálogo" para la **tecla de repetir**.
3. **Deduplica** la misma línea durante 0.5 s — clave porque Essentials a menudo muestra el mismo mensaje
   en su versión "pausada" y "no pausada", y sin dedup se oiría dos veces.

Úsalo solo para diálogo; para opciones de menú usa `speak`.

---

## 2. Limpiar texto: `PokeAccess.clean`

Los strings de Essentials llevan códigos de control (`\PN` = nombre del jugador, `\v[3]` = variable,
`\c[2]` = color, `\1`/`\2` = esperar input) y a veces etiquetas tipo HTML. **Habla siempre texto
limpio**: pasa por `clean` cualquier cosa que venga del juego antes de `speak`.

```ruby
PokeAccess.speak(PokeAccess.clean(raw_label), true)
```

`clean` sustituye `\PN`/`\v[n]`, elimina los `\X`/`\X[..]`, las etiquetas `<...>`, y los bytes de control
`\x00-\x1f` (si no se quitan, la línea "pausada" difiere de la normal y se escapa del dedup de
`say_dialogue` → diálogo doble). Texto que generas tú (ya limpio, vía i18n) no necesita `clean`.

---

## 3. Localización: la convención i18n

**Regla dura: ningún texto hablado nuevo se hardcodea.** Cada cadena es una clave resuelta con
`PokeAccess::I18n.t(:clave)`, y el texto de cada idioma vive en `lang/<código>.txt`.

### Formato de `lang/*.txt`

Una clave por línea, `clave=texto`. Líneas en blanco y las que empiezan por `#` se ignoran.
Interpolación con `%{nombre}`:

```
# combate
bt_hp_change=%{name} %{verb} %{n} PS. %{rest}
dbk_ball=%{name}, %{n}
```

### Usar una clave

```ruby
PokeAccess::I18n.t(:bt_shift)                                   # sin variables
PokeAccess::I18n.t(:dbk_ball, :name => item.name, :n => count) # con %{name} y %{n}
```

`t` busca la clave en el idioma activo, cae al idioma de referencia (`:en`) y, si tampoco está, devuelve
el **nombre de la clave** — así un hueco se ve pero **nunca peta**. El idioma activo sale de
`Config.language`; `available_languages` lista los `lang/*.txt` presentes.

### Paridad es/en OBLIGATORIA

Cada clave nueva debe existir **en `lang/es.txt` Y en `lang/en.txt`** con el mismo nombre. Comprobación
rápida (debe decir "ninguna huérfana"):

```bash
python -c "es=set(l.split('=',1)[0] for l in open('lang/es.txt',encoding='utf-8') if '=' in l and l[0] not in '#_'); en=set(l.split('=',1)[0] for l in open('lang/en.txt',encoding='utf-8') if '=' in l and l[0] not in '#_'); print('solo es:',es-en,'| solo en:',en-es)"
```

---

## 4. ¿Clave i18n o string del juego? (la decisión que más se repite)

Al escribir un lector, parte del texto lo pones tú y parte viene del juego. La regla:

| Qué dices | Cómo |
|-----------|------|
| Etiqueta FIJA del mod (categoría, "Volver", "nivel %{n}", "PS %{hp} de %{tot}") | **clave i18n** (`t(:dbk_back)`...) |
| Dato DINÁMICO del juego ya en su idioma (nombre de objeto, descripción de una carta, nombre de personaje) | **el string del juego tal cual**, pasado por `clean` |
| Nombre de especie / movimiento / objeto por id | `PokeAccess::Data.species_name(id)` etc. (el provider lo localiza) |

El proyecto habla **español** (es su idioma), así que un string dinámico que el juego ya da en español se
dice tal cual — eso respeta el idioma del proyecto y no tiene sentido re-traducirlo. Lo que **sí** va por
clave es todo lo que el mod añade de su cosecha, para que tenga paridad es/en.

> Excepción documentada: en algunos juegos gen-6 hay strings que solo existen en español; pueden quedarse
> literales, pero préfierase la clave i18n siempre que sea una etiqueta fija del mod.

---

## 5. Diagnóstico

Si un lector no se oye, los fallos de su cuerpo se registran (deduplicados) en
`accessibility/data/hook_loaded.txt` vía `PokeAccess.log_once(clave, e)` / el `run_body` del motor de
hooks — así una pantalla que se quedó muda por un método renombrado deja rastro en vez de silencio sin
pista. Ver el flujo completo en [14_EXTENDING.md §7](14_EXTENDING.md).

## Próximo

- [16_CONFIG_MENU.md](16_CONFIG_MENU.md) — el menú de configuración que ve el usuario
- [14_EXTENDING.md](14_EXTENDING.md) — escribir lectores
