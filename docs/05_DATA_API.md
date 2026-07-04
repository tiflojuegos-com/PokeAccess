# Data API - Acceso Agnóstico a Datos

## El Problema: Datos Fragmentados

Essentials guarda información de Pokémon de formas COMPLETAMENTE DIFERENTES:

### Gen-6 (v16-v17)
```ruby
# Gen-6: Constantes globales
PBSpecies.getName(123)           # → "Scyther"
PBTypes.getName(1)               # → "Normal"
PBMoves.getName(1)               # → "Tackle"
PBItems.getName(1)               # → "Poké Ball"

# Datos: constantes en tables.txt (compiladas en RMXP)
# Cada tabla: array de hashes
# Acceso: directa vía índice
```

### Era GameData (v19+)
```ruby
# Era GameData: Clases GameData
GameData::Species.get(123).name   # → "Scyther"
GameData::Type.get(1).name        # → "Normal"
GameData::Move.get(1).name        # → "Tackle"
GameData::Item.get(1).name        # → "Poké Ball"

# Datos: archivos YAML compilados a memoria
# Cada dato: objeto con propiedades
# Acceso: vía objetos con getters
```

**Solución**: Provider Pattern - un adaptador por versión, interfaz única

## Arquitectura Provider

### Definición de Provider

```ruby
class MyDataProvider
  # Cada método corresponde a un tipo de consulta
  
  def species_name(id)
    # Retorna nombre de especie por ID
  end
  
  def move_type_name(id)
    # Retorna nombre del tipo de movimiento por ID
  end
end
```

### Registro de Provider

```ruby
# core/data/gen6/data_g6.rb -- es un MÓDULO (no una clase con .new). Ruby 1.8.7: sin &.
# Los resolvers van CRUDOS (sin rescue): PokeAccess::Data.resolve envuelve cada llamada nil-safe.
module PokeAccess::DataG6
  def self.species_name(id); PBSpecies.getName(id); end
end

PokeAccess::Data.register(10, PokeAccess::DataG6) if defined?(PBMoves) && !defined?(GameData)  # Prioridad 10

# core/data/v21/data_v21.rb -- también un MÓDULO
module PokeAccess::DataV21
  def self.species_name(id); GameData::Species.get(id).name; end
end

PokeAccess::Data.register(20, PokeAccess::DataV21) if defined?(GameData) && defined?(GameData::Move)  # Prioridad 20
```

### Selección Automática

```ruby
module PokeAccess::Data
  @providers = []

  def self.register(priority, provider)
    @providers.push([priority, provider]); @active_entry = nil
  end

  def self.active_entry
    # [prioridad, provider] de MÁS ALTA prioridad, memoizado hasta el próximo register
    @active_entry ||= @providers.max_by { |pr| pr[0] }
  end

  def self.active
    e = active_entry; e && e[1]
  end

  # Cada lector público delega en resolve, que llama al provider activo bajo un begin/rescue
  def self.species_name(id); resolve(:species_name, id); end

  def self.resolve(method, arg)
    pr = active
    return nil unless pr
    begin
      pr.send(method, arg)
    rescue StandardError => e
      note_error(method, e)  # Log una sola vez, sin crashear
      nil
    end
  end
end

# Uso:
PokeAccess::Data.species_name(123)  # Automáticamente usa provider correcto
```

**¿Por qué prioridades?**

```
Prioridad 20 (GameData, v19+)   ← GANADOR
Prioridad 10 (gen-6 v16-17)   ← Ignorado
Prioridad 0 (fallback)        ← Último recurso

En gen-6 (no se registra el provider de la era GameData):
Prioridad 10 (gen-6 v16-17)   ← GANADOR
Prioridad 0 (fallback)        ← Último recurso
```

## Interfaz de Data

### Métodos de Lectura

```ruby
module PokeAccess::Data
  # Movimiento
  def self.move_name(id)              # "Tackle"
  def self.move_type_name(id)         # "Normal"
  def self.move_power(id)             # 40
  def self.move_accuracy(id)          # 100
  def self.move_description(id)       # "Ataca al oponente de frente..."
  
  # Tipo
  def self.type_name(id)              # "Fire"
  
  # Objeto
  def self.item_name(id)              # "Potion"
  def self.item_name_plural(id)       # "Potions" (nombre en plural para cantidades > 1)
  def self.item_description(id)       # "Recupera 20 HP..."
  def self.item_id(sym)               # :POTION → 1
  
  # Especie
  def self.species_name(id)           # "Pikachu"
  def self.species_entry(id)          # Dex entry
  
  # Habilidad
  def self.ability_name(id)           # "Static"
  
  # Naturaleza
  def self.nature_name(id)            # "Timid"
  
  # Estadísticas
  def self.stat_name(s)               # "Atk" para :ATTACK
  def self.status_name(st)            # "Poison" para :POISON
  
  # Pokémon
  def self.pokemon_types(pk)          # ["Fire", "Flying"] (nombres, no símbolos)
end
```

## Implementación por Versión

### Gen-6 Provider

**Archivo**: `core/data/gen6/data_g6.rb`

```ruby
# Es un MÓDULO con métodos de clase. Ruby 1.8.7: nada de &., -> ni Array#first(n).
# Resolvers CRUDOS: PokeAccess::Data envuelve cada llamada nil-safe, así no se repite un rescue por método.
module PokeAccess::DataG6
  def self.move_name(id);        PBMoves.getName(id); end
  def self.move_power(id);       PBMoveData.new(id).basedamage; end
  def self.move_accuracy(id);    PBMoveData.new(id).accuracy; end
  def self.move_type_name(id);   PBTypes.getName(PBMoveData.new(id).type); end
  def self.type_name(id);        PBTypes.getName(id); end
  def self.item_name(id);        PBItems.getName(id); end
  def self.item_name_plural(id); PBItems.getNamePlural(id); end
  def self.species_name(id);     PBSpecies.getName(id); end
  # Más métodos...
end

PokeAccess::Data.register(10, PokeAccess::DataG6) if defined?(PBMoves) && !defined?(GameData)
```

**¿Qué es PBSpecies?**
- Constante global en gen-6
- Módulo con métodos de clase
- `PBSpecies.getName(123)` busca en tabla de especies

### Provider era GameData

**Archivo**: `core/data/v21/data_v21.rb`

```ruby
# También un MÓDULO. Encadena directo (.name); la seguridad ante nil la da Data.resolve, no &.
module PokeAccess::DataV21
  def self.species_name(id);   GameData::Species.get(id).name; end
  def self.move_name(id);      GameData::Move.get(id).name; end
  def self.move_power(id);     GameData::Move.get(id).power; end
  def self.move_accuracy(id);  GameData::Move.get(id).accuracy; end
  def self.move_type_name(id); GameData::Type.get(GameData::Move.get(id).type).name; end
  def self.type_name(id);      GameData::Type.get(id).name; end
  def self.item_name(id);      GameData::Item.get(id).name; end

  # El plural cae a portion_name_plural, luego portion_name, y por último al nombre singular.
  def self.item_name_plural(id)
    d = GameData::Item.get(id)
    (d.portion_name_plural rescue nil) || (d.portion_name rescue nil) || d.name
  end

  # Más métodos...
end

PokeAccess::Data.register(20, PokeAccess::DataV21) if defined?(GameData) && defined?(GameData::Move)
```

**¿Qué es GameData?**
- Namespace en Essentials (era GameData)
- Contiene clases: `Species`, `Move`, `Type`, `Item`, etc.
- Cada clase tiene método `.get(id)` que devuelve objeto
- Objeto tiene propiedades: `.name`, `.type`, `.power`, etc.

### Fallback Provider

**Archivo**: `core/data/data_fallback.rb`

```ruby
module PokeAccess::DataFallback
  # Último recurso: devuelve el ID crudo como string (sin prefijo), para que nunca quede mudo.
  def self.species_name(id)
    id.to_s
  end

  def self.move_name(id)
    id.to_s
  end

  def self.item_name_plural(id)
    id.to_s
  end

  # Etc.
end

PokeAccess::Data.register(0, PokeAccess::DataFallback)  # Prioridad 0 = siempre último
```

## Uso en el Código

### Ejemplo 1: Lectura Simple

```ruby
# En cualquier módulo de PokeAccess:
module PokeAccess::Locator
  def self.announce_pokemon(pokemon_id)
    # Obtener nombre sin importar versión
    name = PokeAccess::Data.species_name(pokemon_id)
    PokeAccess.speak("Es un #{name}")
  end
end

# Funciona automáticamente:
# - Gen-6: Llama PBSpecies.getName()
# - Era GameData: Llama GameData::Species.get().name
```

### Ejemplo 2: Cadena de Información

```ruby
module PokeAccess::Battle
  def self.describe_move(move_id)
    name = PokeAccess::Data.move_name(move_id)
    type = PokeAccess::Data.move_type_name(move_id)
    power = PokeAccess::Data.move_power(move_id)
    
    "#{name} del tipo #{type}, poder #{power}"
  end
end
```

### Ejemplo 3: Búsqueda Inversa

```ruby
def self.get_item_id(symbol)
  # :POTION → 1
  # Useful para config/scripts
  PokeAccess::Data.item_id(:POTION)
end
```

## Errores y Recuperación

### Excepciones Registradas

```ruby
def self.resolve(method, arg)
  pr = active
  return nil unless pr
  
  begin
    pr.send(method, arg)
  rescue StandardError => e
    note_error(method, e)  # Registra UNA SOLA VEZ
    nil
  end
end

# En diagnóstico (Ctrl+Alt+F9):
# [diag] data provider error -- species_name: NoMethodError: undefined method 'name' for nil:NilClass
# Esto significa: el provider intentó llamar .name en nil (la especie no existe)
```

### Qué Sucede si un Provider Falla

```
1. Provider lanza excepción
2. Se registra en PokeAccess::Data.errors
3. Retorna nil
4. Código que lo llamó:
   - Si espera nil: degradación elegante
   - Si no: puede reventar (pero solo si el código es malo)

# Ejemplo bueno:
name = PokeAccess::Data.species_name(999)
PokeAccess.speak(name || "Pokémon desconocido")  # Funciona si nil

# Ejemplo malo:
name = PokeAccess::Data.species_name(999)
PokeAccess.speak(name.upcase)  # CRASHEA si nil
```

## Caching y Rendimiento

### Sin Caching

```ruby
# Cada frame:
10.times do
  name = PokeAccess::Data.species_name(25)  # Busca tabla cada vez
end
```

### Con Caching Manual

```ruby
@species_names = {}

def get_species_name(id)
  @species_names[id] ||= PokeAccess::Data.species_name(id)
end

# Después: búsqueda en hash (O(1)) en lugar de tabla
```

### Validación

PokeEssentialsAccess no cachea automáticamente, pero:
- Gen-6: Las tablas son constantes (no cambian)
- Era GameData: GameData es singleton (tampoco cambia)

**Impacto**: Es seguro cachear indefinidamente

## Extending Data API

### Añadir Método Personalizado

```ruby
# En módulo propio:
module PokeAccess::MyModule
  def self.get_pokemon_info(id)
    {
      name: PokeAccess::Data.species_name(id),
      types: PokeAccess::Data.pokemon_types(id),
      # ... más datos
    }
  end
end
```

### Crear Provider Personalizado

```ruby
# Para juego personalizado que extiende Essentials:
class MyGameDataProvider
  def species_name(id)
    # Lógica personalizada
    (MyGameData::Species[id].custom_name rescue nil)
  end
end

PokeAccess::Data.register(75, MyGameDataProvider.new)  # Prioridad 75 > 20 (GameData) > 10 (gen6): gana sobre ambos
```

## Diagnóstico

### Ver Provider Activo

```ruby
# En código:
pr = PokeAccess::Data.active   # → PokeAccess::DataV21 o PokeAccess::DataG6 (un módulo)
PokeAccess::Data.active_priority  # → 20 (GameData), 10 (gen-6) o 0 (fallback)

# Un error de provider se registra en el marker así:
# data provider error -- species_name: NoMethodError: undefined method 'name' for nil
```

### Ver Errores

```ruby
errors = PokeAccess::Data.errors
puts errors.inspect
# ["species_name: NoMethodError: undefined method 'type' for nil:NilClass"]
```

## Tabla Rápida: Mapeo Gen-6 → era GameData

| Función Gen-6 | Era GameData | Provider | Método |
|---|---|---|---|
| `PBSpecies.getName(id)` | `GameData::Species.get(id).name` | ✓ | `species_name(id)` |
| `PBMoves.getName(id)` | `GameData::Move.get(id).name` | ✓ | `move_name(id)` |
| `PBTypes.getName(id)` | `GameData::Type.get(id).name` | ✓ | `type_name(id)` |
| `PBItems.getName(id)` | `GameData::Item.get(id).name` | ✓ | `item_name(id)` |
| `PBItems.getNamePlural(id)` | `GameData::Item.get(id).portion_name_plural` | ✓ | `item_name_plural(id)` |
| `PBAbilities.getName(id)` | `GameData::Ability.get(id).name` | ✓ | `ability_name(id)` |
| `PBNatures.getName(id)` | `GameData::Nature.get(id).name` | ✓ | `nature_name(id)` |
| `PBMoveData.new(id).type` | `GameData::Move.get(id).type` | ✓ | `move_type_name(id)` |
| `PBMoveData.new(id).basedamage` | `GameData::Move.get(id).power` | ✓ | `move_power(id)` |
| `PBMoveData.new(id).accuracy` | `GameData::Move.get(id).accuracy` | ✓ | `move_accuracy(id)` |

## MoveInfo: detalle hablado de un movimiento

**Archivo**: `core/battle/move_info.rb`

`PokeAccess::MoveInfo` centraliza el formateo del detalle de un movimiento (nombre, tipo, poder, precisión, descripción) para que todos los lectores de movimientos (combate, relearner, tutores de huevo, página de movimientos del resumen) hablen la misma línea. Antes había copias divergentes que discrepaban (un movimiento de poder 1 llegó a leerse como "sin daño" en combate).

Piezas clave:

- `MoveInfo.power_phrase(pw)` — "sin daño" si el poder es <= 0, "variable" si es 1 (daño fijo o por nivel), si no el número. Textos vía `PokeAccess::I18n.t`.
- `MoveInfo.accuracy_phrase(acc)` — "nunca falla" si <= 0 (el centinela "siempre acierta" del motor), si no el valor.
- `MoveInfo.line(name, type_name, power, accuracy, opts = {})` — arma "nombre. tipo. poder. precisión[. pp][. descripción]" a partir de partes ya resueltas. Opciones: `:pp` y `:total_pp` (ambos requeridos para hablar los PP) y `:desc`.

Dos resolutores por id:

```ruby
# Resuelve vía GameData directamente (compartido por v21 y v22). nil si el id no resuelve.
PokeAccess::MoveInfo.by_id(id)

# Resuelve a través del adaptador Data por-motor (PBMoveData en gen-6, GameData en moderno),
# para que un lector gen-6 también reciba la línea completa. Lo usa el move relearner de gen-6,
# cuyos ids son enteros PBMove planos.
PokeAccess::MoveInfo.by_id_via_data(id)
```

`by_id_via_data` encadena `Data.move_name` / `move_type_name` / `move_power` / `move_accuracy` / `move_description` y devuelve nil si el nombre resuelve a vacío. Es el motivo por el que gen-6 SÍ expone poder/precisión/tipo de un movimiento (vía `PBMoveData.new(id)`), no solo el moderno.

## Referencias

- [Data Module](core/data/data.rb)
- [Gen-6 Provider](core/data/gen6/data_g6.rb)
- [GameData Provider](core/data/v21/data_v21.rb)
- [Fallback](core/data/data_fallback.rb)
- [MoveInfo](core/battle/move_info.rb)

## Próximo

- [Pathfinding](06_PATHFINDING.md) - Navegación por rutas
- [Audio3D](07_AUDIO3D.md) - Sonido posicional
