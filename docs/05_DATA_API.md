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
module PokeAccess::DataG6
  def self.species_name(id)
    PBSpecies.getName(id) rescue nil
  end
end

PokeAccess::Data.register(10, PokeAccess::DataG6) if defined?(PBMoves) && !defined?(GameData)  # Prioridad 10

# core/data/v21/data_v21.rb -- también un MÓDULO
module PokeAccess::DataV21
  def self.species_name(id)
    (GameData::Species.get(id).name rescue nil)
  end
end

PokeAccess::Data.register(20, PokeAccess::DataV21) if defined?(GameData)  # Prioridad 20
```

### Selección Automática

```ruby
module PokeAccess::Data
  @providers = []
  
  def self.active
    # Devuelve el provider de MÁS ALTA prioridad registrado
    entry = @providers.max_by { |pr| pr[0] }
    entry && entry[1]
  end
  
  def self.species_name(id)
    pr = active
    return nil unless pr
    
    begin
      pr.send(:species_name, id)
    rescue StandardError => e
      # Log error sin crashear
      note_error(:species_name, e)
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
  def self.pokemon_types(pk)          # [:fire, :flying]
end
```

## Implementación por Versión

### Gen-6 Provider

**Archivo**: `core/data/gen6/data_g6.rb`

```ruby
# Es un MÓDULO con métodos de clase. Ruby 1.8.7: nada de &., -> ni Array#first(n).
module PokeAccess::DataG6
  def self.species_name(id)
    PBSpecies.getName(id) rescue nil
  end

  def self.move_name(id)
    PBMoves.getName(id) rescue nil
  end

  def self.type_name(id)
    PBTypes.getName(id) rescue nil
  end

  def self.item_name(id)
    PBItems.getName(id) rescue nil
  end

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
  def self.species_name(id)
    (GameData::Species.get(id).name rescue nil)
  end

  def self.move_name(id)
    (GameData::Move.get(id).name rescue nil)
  end

  def self.move_type_name(id)
    move = GameData::Move.get(id)
    return nil unless move
    (GameData::Type.get(move.type).name rescue nil)
  end

  def self.type_name(id)
    (GameData::Type.get(id).name rescue nil)
  end

  def self.item_name(id)
    (GameData::Item.get(id).name rescue nil)
  end

  # Más métodos...
end

PokeAccess::Data.register(20, PokeAccess::DataV21) if defined?(GameData)
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

PokeAccess::Data.register(75, MyGameDataProvider.new)  # Entre gen6 y era GameData
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
| `PBAbilities.getName(id)` | `GameData::Ability.get(id).name` | ✓ | `ability_name(id)` |
| `PBNatures.getName(id)` | `GameData::Nature.get(id).name` | ✓ | `nature_name(id)` |
| No existe | `GameData::Move.get(id).type` | ✓ | `move_type_name(id)` |
| No existe | `GameData::Move.get(id).power` | ✓ | `move_power(id)` |

## Referencias

- [Data Module](core/data/data.rb)
- [Gen-6 Provider](core/data/gen6/data_g6.rb)
- [GameData Provider](core/data/v21/data_v21.rb)
- [Fallback](core/data/data_fallback.rb)

## Próximo

- [Pathfinding](06_PATHFINDING.md) - Navegación por rutas
- [Audio3D](07_AUDIO3D.md) - Sonido posicional
