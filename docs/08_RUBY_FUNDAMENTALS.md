# Fundamentos de Ruby Necesarios

PokeEssentialsAccess utiliza conceptos avanzados de Ruby. Este documento explica los mínimos necesarios para entender el código.

## 1. Módulos (Modules)

**¿Qué es?** Contenedor de métodos y constantes (como clase pero sin instanciación).

```ruby
# Definir módulo
module MiModulo
  VERSION = "1.0"
  
  def self.mi_metodo
    "Hola"
  end
end

# Usar módulo
MiModulo::VERSION              # → "1.0"
MiModulo.mi_metodo             # → "Hola"

# Namespace (organización)
module PokeAccess
  module Pathfinder
    def self.find_path(x, y)
      # ...
    end
  end
end

PokeAccess::Pathfinder.find_path(10, 20)
```

**Ventajas**: Organización, no hay conflicto de nombres

## 2. Métodos de Clase

```ruby
module PokeAccess
  def self.speak(text)  # ← "self." = método de módulo/clase
    # Solo se puede llamar: PokeAccess.speak("hola")
    # NO: PokeAccess.new.speak("hola")
  end
end
```

## 3. Instancias Variables (Instance Variables)

```ruby
module PokeAccess
  @global_state = {}  # ← Empieza con @
  
  def self.get_state
    @global_state  # Acceder dentro del módulo
  end
  
  def self.set_state(value)
    @global_state = value
  end
end
```

**Nota**: `@global_state` es privado al módulo (no se ve desde afuera).

## 4. attr_accessor

```ruby
# Crear getters/setters automáticamente
class MiClase
  attr_accessor :nombre  # Crea nombre() y nombre=(valor)
  attr_reader :edad      # Solo getter (edad())
  attr_writer :email     # Solo setter (email=(valor))
end

obj = MiClase.new
obj.nombre = "Juan"      # Llama nombre=(...)
puts obj.nombre          # Llama nombre()
```

**En PokeEssentialsAccess**:
```ruby
module PokeAccess::Config
  # Crear getters/setters para todas las opciones
  attr_accessor(*(SCHEMA.map { |row| row[0] } + OTHER))
  
  # Expande a:
  # attr_accessor :language, :auto_guide, :hide_unreachable, ...
end

PokeAccess::Config.language = :es
puts PokeAccess::Config.language  # → :es
```

## 5. Bloques y Yields

```ruby
# Bloque = código pasado a método con &block
def mi_metodo(&block)
  block.call("argumento")
end

mi_metodo { |x| puts x }
# OUTPUT: argumento

# ¿Sin variable &block?
def mi_metodo
  yield("argumento")
end

mi_metodo { |x| puts x }
# OUTPUT: argumento
```

**En PokeEssentialsAccess**:
```ruby
# Registrar callback que se ejecuta después
PokeAccess::Hooks.after_hook("MiClase", :metodo) do |obj, result, args|
  # Este bloque se ejecuta cuando MiClase#metodo termina
end

# Emitir evento a todos los suscriptores
PokeAccess::Events.on(:mapa_cambio) do |mapa_id|
  # Este bloque se ejecuta cuando cambia el mapa
end
```

## 6. Lambda y Proc

```ruby
# Lambda = función almacenada en variable
increment = lambda { |x| x + 1 }
increment.call(5)  # → 6

# Equivalente:
increment = proc { |x| x + 1 }

# En PokeAccess:
h = lambda { (x - goal_x).abs + (y - goal_y).abs }
distance = h.call(10, 20)  # Heurística Manhattan para A*
```

## 7. Hash

```ruby
# Diccionario clave → valor
mi_hash = {
  :nombre => "Juan",
  :edad => 30,
  "ciudad" => "Madrid"
}

mi_hash[:nombre]         # → "Juan"
mi_hash[:nombre] = "Carlos"

# Acceso seguro (no crashea si no existe)
mi_hash[:pais] || "España"  # → "España"

# Iteración
mi_hash.each do |clave, valor|
  puts "#{clave}: #{valor}"
end

# Con default
defaults = Hash.new(0)
defaults[:x] += 1  # → 1 (0 + 1)
defaults[:x] += 1  # → 2 (1 + 1)
```

**En PokeEssentialsAccess**:
```ruby
# Caché de rutas
@pcache = {}
@pcache[pkey(10, 20)] = true

# Providers data
@providers = []
@providers.push([priority, provider])
pr = @providers.max_by { |pr| pr[0] }
```

## 8. Array

```ruby
arr = [1, 2, 3, 4, 5]
arr[0]           # → 1
arr[-1]          # → 5
arr.push(6)      # → [1, 2, 3, 4, 5, 6]
arr.shift        # → 1, arr = [2, 3, 4, 5, 6]

arr.each { |x| puts x }
arr.map { |x| x * 2 }      # → [2, 4, 6, 8, 10]
arr.select { |x| x > 2 }   # → [3, 4, 5]
```

**En PokeEssentialsAccess**:
```ruby
# Manifest = array de strings
list = %w[foundation/config foundation/engine data/data ...]

# Iteración
list.each { |entry| load_module("#{dir}/#{entry}.rb") }

# Búsqueda
spec_row = SCHEMA.select { |row| row[0] == :language }
```

## 9. Symbol (:)

```ruby
# Símbolo = string inmutable (se reutiliza)
:nombre    # Símbolo
"nombre"   # String

:nombre == :nombre  # true (mismo objeto)
"nombre" == "nombre"  # true (objetos diferentes)

# Útil para claves de hash
config = { :language => :es, :auto_guide => false }
config[:language]  # → :es

# Símbolo a string
:nombre.to_s       # → "nombre"

# String a símbolo
"nombre".to_sym    # → :nombre
```

**En PokeEssentialsAccess**:
```ruby
# Configuración
[:language, :es, :lang, :general, ...]

# Engine detection
Engine.kind       # → :gamedata o :gen6
Engine.fork       # → :sky o nil

# Data API
Data.species_name(123)  # Usando símbolo internamente
```

## 10. Define_method

```ruby
# Definir método dinámicamente
class MiClase
  define_method(:saludar) do
    "Hola"
  end
end

MiClase.new.saludar  # → "Hola"

# Con parámetros
define_method(:sumar) do |a, b|
  a + b
end
```

**En PokeEssentialsAccess**:
```ruby
# Crear setters automáticamente
SCHEMA.each do |row|
  key = row[0]
  default = row[1]
  
  define_method("#{key}=") do |value|
    instance_variable_set("@#{key}", value)
  end
end
```

## 11. Instance_variable_get/set

```ruby
# Acceder a variables privadas de otros objetos
class MiClase
  def initialize
    @privado = "secreto"
  end
end

obj = MiClase.new
obj.instance_variable_get(:@privado)  # → "secreto"
obj.instance_variable_set(:@privado, "nuevo")
```

**En PokeEssentialsAccess**:
```ruby
# Leer el movimiento actual del jugador en batalla
battler = menu.instance_variable_get(:@battler)
moves = battler.moves
```

## 12. Alias_method

```ruby
class MiClase
  def metodo_original
    "original"
  end
  
  # Guardar referencia
  alias_method :metodo_viejo, :metodo_original
  
  # Redefinir
  def metodo_original
    "modificado: " + metodo_viejo
  end
end

MiClase.new.metodo_original  # → "modificado: original"
```

**En PokeEssentialsAccess**:
```ruby
# Envolver Graphics.update sin perder original
alias_method :update__access_preload, :update
def update(*a)
  r = update__access_preload(*a)  # Llamar original
  AccessPreload.try_load         # Código personalizado
  r
end
```

## 13. const_get / const_defined?

```ruby
# Obtener constante por nombre
MyClass = "definida"
Object.const_get("MyClass")  # → "definida"

# Verificar si existe
Object.const_defined?("MyClass")  # → true
Object.const_defined?("NoExiste")  # → false

# Seguro (no crashea)
(Object.const_get("NoExiste") rescue nil)  # → nil
```

**En PokeEssentialsAccess**: NO se usa `Object.const_defined?`/`const_get` directo con nombres anidados (`"A::B::C"`),
porque en Ruby 1.8.7 (gen-6) `const_defined?` rechaza un nombre con `"::"` y lanza error. En su lugar hay
una primitiva única, 1.8.7-safe, que recorre los segmentos uno a uno:

```ruby
# core/foundation/const.rb -- la usan Hooks, Input, Menus, Engine.has?
PokeAccess.const_at("Battle::Scene")          # → la clase, o nil si algún segmento falta
PokeAccess.const?("UI::BagVisuals")           # → true / false

# Registrar hooks solo si la clase existe:
klass = PokeAccess.const_at("Battle::Scene")
return if klass.nil?  # No existe → NO hacer nada

# Para gatear por capacidad (clase + método), usa Engine.has?:
PokeAccess::Engine.has?("Battle::Scene#setIndexAndMode")
```

## 14. Rescue (Manejo de Errores)

```ruby
begin
  1 / 0  # Error!
rescue ZeroDivisionError => e
  puts "Error: #{e.message}"
  puts e.backtrace.join("\n")
end

# Forma corta
result = risky_operation rescue default_value

# Múltiples rescues
begin
  # código
rescue NoMethodError => e
  puts "Método no existe"
rescue StandardError => e
  puts "Otro error"
end

# Ensure (siempre ejecuta)
begin
  # código
ensure
  puts "Esto SIEMPRE se ejecuta"
end
```

**En PokeEssentialsAccess**:
```ruby
def resolve(method, arg)
  pr = active
  return nil unless pr
  
  begin
    pr.send(method, arg)
  rescue StandardError => e
    note_error(method, e)
    nil
  end
end
```

## 15. Send y Method

```ruby
# Llamar método por nombre (dinámica)
obj = "hola"
obj.send(:upcase)  # → "HOLA"
obj.send(:length)  # → 5

# Con argumentos
obj.send(:[], 0)   # → "h" (mismo que obj[0])

# Obtener método
m = obj.method(:upcase)
m.call  # → "HOLA"
```

**En PokeEssentialsAccess**:
```ruby
# Llamar método del provider
provider.send(:species_name, 123)

# En Data.resolve:
pr.send(method, arg)  # Llama pr.move_name(id), etc.
```

## 16. Regex

```ruby
# Expresión regular
version_string = "21.1"
version_string[/\d+(\.\d+)?/]  # → "21.1"

str = "Essentials v22_1a"
str[/\d+/]  # → "22"

# Reemplazar
text = "Señor   José"
text.gsub(/\s+/, " ")  # → "Señor José"
```

**En PokeEssentialsAccess**:
```ruby
# Parsear versión de string
ev.to_s[/\d+(\.\d+)?/].to_f  # Extraer número flotante
```

## 17. Ternary Operator

```ruby
x = 5
resultado = x > 3 ? "grande" : "pequeño"  # → "grande"

# Es equivalente a:
if x > 3
  resultado = "grande"
else
  resultado = "pequeño"
end
```

**En PokeEssentialsAccess**:
```ruby
# Elegir según engine
adapter = Engine.gamedata? ? GameDataBattle : GenSixBattle
```

## 18. Lazy Initialization (||=)

```ruby
@cache ||= {}  # Si @cache es nil, crear {}; si no, usar lo que hay

@cache ||= {}
@cache[:x] = 5  # Guardar en caché

@cache ||= {}   # Ya existe, no hacer nada
```

**En PokeEssentialsAccess**:
```ruby
def active_entry
  @active_entry ||= @providers.max_by { |pr| pr[0] }
end

# Primera llamada: calcular y guardar
# Siguientes: devolver lo guardado (sin recalcular)
```

## 19. Splat Operator (*)

```ruby
def mi_metodo(*args)  # Captura TODOS los argumentos en array
  args.each { |arg| puts arg }
end

mi_metodo(1, 2, 3)  # args = [1, 2, 3]

# Expandir array
arr = [1, 2, 3]
mi_otro_metodo(*arr)  # Se vuelve: mi_otro_metodo(1, 2, 3)
```

**En PokeEssentialsAccess** (los hooks reciben los argumentos del método original como array):
```ruby
PokeAccess::Hooks.after_hook("Algo_Scene", :metodo) do |scene, result, args|
  # args = los argumentos con que se llamó al método original
end
```

## 20. Class.new y Class.define_method

```ruby
# Crear clase dinámicamente
MiClase = Class.new do
  def mi_metodo
    "resultado"
  end
end

MiClase.new.mi_metodo  # → "resultado"
```

## Resumen Rápido

| Concepto | Sintaxis | Uso en PokeEssentialsAccess |
|----------|----------|-------------------|
| Módulo | `module X; end` | Organización de código |
| Método clase | `def self.m; end` | `PokeAccess.speak()` |
| Variable instancia | `@var` | Cache, estado |
| Bloque | `{ \|x\| x + 1 }` | Hooks, eventos |
| Hash | `{ :key => val }` | Config, datos |
| Array | `[1, 2, 3]` | Manifests, listas |
| Símbolo | `:symbol` | Claves, tipos |
| Rescue | `begin...rescue` | Errores sin crashear |
| ||= | `x ||= default` | Inicialización perezosa |
| ? : | `condition ? a : b` | Decisiones rápidas |

## Referencias

- [Ruby Official Docs](https://ruby-doc.org)
- [Ruby Style Guide](https://rubystyle.guide)

## Próximo

- [Volver a Introducción](01_INTRODUCTION.md)
- [Architecture](02_ARCHITECTURE.md)
